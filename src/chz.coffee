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
    limit: '='
  require: '?ngModel'
  replace: true
  transclude: true
  templateUrl: "/templates/chz.html"
  controller: ($scope, $element, $attrs) ->
    move = (d) ->
      newIndex = $scope.normalizeIndex($scope.activeIndex + d)

      if newIndex != $scope.activeIndex
        delta = newIndex - $scope.activeIndex
        $scope.activeIndex = newIndex
        if  newIndex < $scope.firstShown or $scope.lastShown() < newIndex
          $scope.firstShown =  $scope.normalizeIndex($scope.firstShown + delta)
          search($scope.prevSearch)
        else
          $scope.activeItem = $scope.foundItems[$scope.activeIndex]

    search = (q) ->
      if $scope.prevSearch != q
        $scope.activeIndex = 0
        $scope.firstShown = 0
        $scope.foundItems = filter(q, $scope.items)
      $scope.shownItems = $scope.foundItems[$scope.firstShown..$scope.lastShown()]
      $scope.prevSearch = q
      $scope.activeItem = $scope.foundItems[$scope.activeIndex]

    $scope.selection = (item)->
      $scope.selectedItem = $scope.activeItem = item
      $scope.hideDropDown()

    $scope.onkeys = (key)->
       switch key
         when 40 then move(1)
         when 38 then move(-1)
         when 33 then move(-1 * $scope.shownAmount())
         when 34 then move($scope.shownAmount())
         when 13 then $scope.selection($scope.activeItem)
         when 27 then $scope.hideDropDown()

    $scope.$watch 'search', search

    $scope.hideDropDown = ->
      $scope.active = false

    $scope.shownAmount = ->
      if $scope.limit > 0 then $scope.limit else $scope.items.length

    $scope.lastShown = ->
      $scope.firstShown + $scope.shownAmount() - 1

    $scope.normalizeIndex = (index)->
      Math.max(Math.min(index, $scope.items.length - 1), 0)

    $scope.firstShown = 0
    $scope.activeIndex = 0
    $scope.activeItem = $scope.items[0]
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
