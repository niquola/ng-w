(function() {
  var comp, filter;

  comp = function(a, b) {
    return a.toString().toLowerCase().indexOf(b.toString().toLowerCase()) > -1;
  };

  filter = function(x, xs) {
    if (x) {
      return xs.filter((function(i) {
        return comp(i, x);
      }));
    } else {
      return xs;
    }
  };

  angular.module("angular-w").directive("wCombo", [
    '$window', function($window) {
      return {
        restrict: "A",
        scope: {
          items: '=',
          limit: '='
        },
        require: '?ngModel',
        replace: true,
        transclude: true,
        templateUrl: "/templates/combo.html",
        controller: function($scope, $element, $attrs) {
          var getActiveIndex, getComputedStyle, move, scrollIfNeeded, search;
          getComputedStyle = function(elem, prop) {
            return parseInt($window.getComputedStyle(elem, null).getPropertyValue(prop));
          };
          move = function(d) {
            var activeIndex, items;
            items = $scope.shownItems;
            activeIndex = getActiveIndex() + d;
            activeIndex = Math.min(Math.max(activeIndex, 0), items.length - 1);
            $scope.activeItem = items[activeIndex];
            return scrollIfNeeded(activeIndex);
          };
          scrollIfNeeded = function(activeIndex) {
            var item, li, liHeight, ul, ulHeight, viewport;
            ul = $element.find('ul')[0];
            li = ul.querySelector('li.active');
            if (!(ul && li)) {
              return;
            }
            ulHeight = ul.clientHeight - getComputedStyle(ul, 'padding-top') - getComputedStyle(ul, 'padding-bottom');
            viewport = {
              top: ul.scrollTop,
              bottom: ul.scrollTop + ulHeight
            };
            li = ul.querySelector('li.active');
            liHeight = li.clientHeight - getComputedStyle(li, 'padding-top') - getComputedStyle(li, 'padding-bottom');
            item = {
              top: activeIndex * liHeight,
              bottom: (activeIndex + 1) * liHeight
            };
            if (item.bottom > viewport.bottom) {
              return ul.scrollTop += item.bottom - viewport.bottom;
            } else if (item.top < viewport.top) {
              return ul.scrollTop -= viewport.top - item.top;
            }
          };
          search = function(q) {
            $scope.shownItems = filter(q, $scope.items).slice(0, $scope.limit);
            if ($scope.shownItems.length === 0) {
              $scope.shownItems.push(q);
              $scope.activeItem = $scope.shownItems[$scope.shownItems.length];
            }
            return $scope.activeItem = $scope.shownItems[0];
          };
          $scope.selection = function(item) {
            $scope.selectedItem = item;
            return $scope.hideDropDown();
          };
          $scope.reset = function() {
            $scope.selectedItem = null;
            return $scope.focus = true;
          };
          $scope.onkeys = function(event) {
            switch (event.keyCode) {
              case 40:
                return move(1);
              case 38:
                return move(-1);
              case 13:
                $scope.selection($scope.activeItem || $scope.search);
                $scope.focus = true;
                return event.preventDefault();
              case 9:
                return $scope.selection($scope.search);
              case 27:
                $scope.hideDropDown();
                return $scope.focus = true;
              case 34:
                return move(11);
              case 33:
                return move(-11);
            }
          };
          $scope.$watch('search', search);
          $scope.$watch('limit', function() {
            return search('');
          });
          $scope.$watch('active', function(value) {
            if (value) {
              return window.setTimeout((function() {
                return scrollIfNeeded(getActiveIndex());
              }), 0);
            }
          });
          $scope.hideDropDown = function() {
            return $scope.active = false;
          };
          getActiveIndex = function() {
            return $scope.shownItems.indexOf($scope.activeItem) || 0;
          };
          return search('');
        },
        link: function(scope, element, attrs, ngModelCtrl, transcludeFn) {
          if (ngModelCtrl) {
            scope.$watch('selectedItem', function() {
              ngModelCtrl.$setViewValue(scope.selectedItem);
              scope.activeItem = scope.selectedItem;
              return scope.search = scope.selectedItem;
            });
            ngModelCtrl.$render = function() {
              return scope.selectedItem = ngModelCtrl.$modelValue;
            };
          }
          attrs.$observe('disabled', function(value) {
            return scope.disabled = value;
          });
          attrs.$observe('required', function(value) {
            return scope.required = value;
          });
          scope.$watch('selectedItem', function() {
            var childScope;
            childScope = scope.$new();
            childScope.item = scope.selectedItem;
            return transcludeFn(childScope, function(clone) {
              var link;
              if (clone.text().trim() !== "") {
                link = element[0].querySelector('a.w-chz-active');
                return angular.element(link).empty().append(clone);
              }
            });
          });
          return $window.addEventListener('click', function(e) {
            var parent;
            parent = $(e.target).parents('div.w-chz')[0];
            if (parent !== element[0]) {
              return scope.$apply(function() {
                scope.hideDropDown();
                return scope.selection(scope.search);
              });
            }
          });
        }
      };
    }
  ]);

}).call(this);
