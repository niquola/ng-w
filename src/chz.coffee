comp = (a, b)->
  a.toLowerCase().indexOf(b.toLowerCase()) > -1

filter = (x, xs)->
  if x then xs.filter ((i)-> comp(i.name, x)) else xs

focuz = (el)->
  window.setTimeout((()-> el.focus()) , 0)

angular
.module("angular-w", [])
.directive "wFocus", ->
  link: (scope, element, attrs) ->
    scope.$watch attrs.wFocus, (fcs)->
      focuz(element[0]) if fcs

angular
.module("angular-w")
.directive "wChz", ['$window', ($window) ->
  restrict: "A"
  scope:
    items: '='
  require: '?ngModel'
  replace: true
  transclude: true
  templateUrl: "/templates/chz.html"
  controller: ($scope, $element, $attrs) ->

    getComputedStyle = (elem, prop) ->
      parseInt $window.getComputedStyle(elem, null).getPropertyValue(prop)

    move = (d) ->
      items = $scope.shownItems
      activeIndex = (items.indexOf($scope.activeItem) || 0) + d
      activeIndex = Math.min(Math.max(activeIndex,0), items.length - 1)
      $scope.activeItem = items[activeIndex]
      scrollIfNeeded(activeIndex)

    scrollIfNeeded = (activeIndex) ->
      ul = $element.find('ul')[0]
      ulHeight = ul.clientHeight - getComputedStyle(ul, 'padding-top') - getComputedStyle(ul, 'padding-bottom')
      viewport =
        top: ul.scrollTop
        bottom: ul.scrollTop + ulHeight

      li = ul.querySelector('li.active')
      liHeight = li.clientHeight - getComputedStyle(li, 'padding-top') - getComputedStyle(li, 'padding-bottom')
      item =
        top: activeIndex * liHeight
        bottom: (activeIndex + 1) * liHeight

      # Scroll down
      if item.bottom > viewport.bottom
        ul.scrollTop += item.bottom - viewport.bottom
      # Scroll up
      else if item.top < viewport.top
        ul.scrollTop -= viewport.top - item.top


    search = (q) ->
      if $scope.prevSearch != q
        $scope.shownItems = filter(q, $scope.items)
        $scope.activeItem = $scope.shownItems[0]
      $scope.prevSearch = q

    $scope.selection = (item)->
      $scope.selectedItem = item
      $scope.hideDropDown()

    $scope.onkeys = (key)->
       switch key
         when 40 then move(1)
         when 38 then move(-1)
         when 13 then $scope.selection($scope.activeItem)
         when 27 then $scope.hideDropDown()
         when 34 then move(11)
         when 33 then move(-11)

    $scope.$watch 'search', search

    $scope.hideDropDown = ->
      $scope.active = false

    # run
    search('')

  link: (scope, element, attrs, ngModelCtrl, transcludeFn) ->
    if ngModelCtrl
      scope.$watch 'selectedItem', ->
        ngModelCtrl.$setViewValue(scope.selectedItem)

      ngModelCtrl.$render = ->
        scope.selectedItem = ngModelCtrl.$modelValue

    attrs.$observe 'disabled', (value) ->
      scope.disabled = value

    attrs.$observe 'required', (value) ->
      scope.required = value

    scope.$watch  'selectedItem', ->
      childScope = scope.$new()
      childScope.item = scope.selectedItem
      transcludeFn childScope, (clone) ->
        if clone.text().trim() isnt ""
          link = angular.element(element.find('a')[0])
          link.empty().append(clone)

    # Hide drop down list on click elsewhere
    $window.addEventListener 'click', (e) ->
      parent = $(e.target).parents('div.w-chz')
      element = $(element[0])
      if not parent.is(element)
        scope.$apply(scope.hideDropDown)
]