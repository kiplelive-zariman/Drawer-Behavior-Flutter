import 'package:drawerbehavior/drawer_scaffold.dart';
import 'package:flutter/material.dart';

final menuScreenKey = GlobalKey(debugLabel: 'MenuScreen');

enum Direction {
  left,
  right,
}

class MenuView<T> extends StatefulWidget {
  MenuView({
    this.menu,
    this.headerView,
    this.footerView,
    this.selectedItemId,
    this.onMenuItemSelected,
    this.color = Colors.white,
    this.background,
    this.animation = false,
    this.direction = Direction.left,
    this.selectorColor,
    this.textStyle,
    this.padding = const EdgeInsets.only(left: 40.0, top: 15.0, bottom: 15.0),
    this.alignment = Alignment.centerLeft,
    this.itemBuilder,
  }) : super(key: menuScreenKey);

  final double maxSlideAmount = 275.0;
  final Direction direction;
  final Menu menu;
  final T selectedItemId;
  final bool animation;
  final Function(T) onMenuItemSelected;

  final Widget headerView;
  final Widget footerView;
  final Function(BuildContext, MenuItem, bool) itemBuilder;
  final DecorationImage background;
  final Color color;

  final Color selectorColor;
  final TextStyle textStyle;
  final Alignment alignment;
  final EdgeInsets padding;

  @override
  _MenuViewState createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> with TickerProviderStateMixin {
  AnimationController titleAnimationController;
  double selectorYTop;
  double selectorYBottom;

  Color selectorColor;
  TextStyle textStyle;

  setSelectedRenderBox(RenderBox newRenderBox, bool useState) async {
    final newYTop = newRenderBox.localToGlobal(const Offset(0.0, 0.0)).dy;
    final newYBottom = newYTop + newRenderBox.size.height;
    if (newYTop != selectorYTop) {
//      setState(() {
      selectorYTop = newYTop;
      selectorYBottom = newYBottom;
//      });
    }
  }

  @override
  void initState() {
    super.initState();
    titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    titleAnimationController.dispose();
    super.dispose();
  }

  Widget createMenuItems(MenuController menuController) {
    final List<Widget> listItems = [];

    final animationIntervalDuration = 0.5;
    final perListItemDelay =
        menuController.state != MenuState.closing ? 0.15 : 0.0;

    final millis = menuController.state != MenuState.closing
        ? 150 * widget.menu.items.length
        : 600;
    final maxDuration = (widget.menu.items.length - 1) * perListItemDelay +
        animationIntervalDuration;
    for (var i = 0; i < widget.menu.items.length; ++i) {
      final animationIntervalStart = i * perListItemDelay;
      final animationIntervalEnd =
          animationIntervalStart + animationIntervalDuration;

      MenuItem item = widget.menu.items[i];

      final isSelected = item.id == widget.selectedItemId;

      Function onTap = () {
        widget.onMenuItemSelected(item.id);
        menuController.close();
      };
      Widget listItem = widget.itemBuilder == null
          ? _MenuListItem(
              padding: const EdgeInsets.only(left: 32.0),
              direction: widget.direction,
              title: item.title,
              isSelected: isSelected,
              selectorColor: selectorColor,
              textStyle: textStyle,
              menuView: widget,
              width: widget.maxSlideAmount,
              icon: item.icon == null ? null : Icon(item.icon),
              onTap: onTap,
              drawBorder: !widget.animation,
            )
          : InkWell(
              child: Container(
                alignment: Alignment.centerLeft,
                child: Container(
                  child: widget.itemBuilder(context, item, isSelected),
                  width: widget.maxSlideAmount,
                ),
              ),
              onTap: onTap,
            );

      if (widget.animation)
        listItems.add(AnimatedMenuListItem(
          menuState: menuController.state,
          isSelected: isSelected,
          duration: Duration(milliseconds: millis),
          curve: Interval(animationIntervalStart / maxDuration,
              animationIntervalEnd / maxDuration,
              curve: Curves.easeOut),
          menuListItem: listItem,
        ));
      else {
        listItems.add(listItem);
      }
    }

    return Container(
      alignment: widget.alignment,
      margin: EdgeInsets.only(
          left: widget.direction == Direction.left
              ? 0
              : MediaQuery.of(context).size.width - widget.maxSlideAmount),
      child: SingleChildScrollView(
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listItems,
          ),
        ),
      ),
    );
  }

  Widget createDrawer(MenuController menuController) {
    List<Widget> widgets = [];
    if (widget.headerView != null) {
      widgets.add(Container(width: double.infinity, child: widget.headerView));
    }
    widgets.add(Expanded(
      child: createMenuItems(menuController),
      flex: 1,
    ));

    if (widget.footerView != null) {
      widgets.add(Container(
        width: double.infinity,
        child: widget.footerView,
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      ));
    }
    return Transform(
      transform: Matrix4.translationValues(
        0.0,
        MediaQuery.of(context).padding.top,
        0.0,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top,
        child: Column(
          children: widgets,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    selectorColor = widget?.selectorColor ?? Theme.of(context).indicatorColor;
    textStyle = widget?.textStyle ??
        Theme.of(context).textTheme.subtitle1.copyWith(
            color: widget.color.computeLuminance() < 0.5
                ? Colors.white
                : Colors.black);
    return DrawerScaffoldMenuController(
        builder: (BuildContext context, MenuController menuController) {
      var shouldRenderSelector = true;
      var actualSelectorYTop = selectorYTop;
      var actualSelectorYBottom = selectorYBottom;
      var selectorOpacity = 1.0;

      if (menuController.state == MenuState.closed ||
          menuController.state == MenuState.closing ||
          selectorYTop == null) {
        final RenderBox menuScreenRenderBox =
            context.findRenderObject() as RenderBox;

        if (menuScreenRenderBox != null) {
          final menuScreenHeight = menuScreenRenderBox.size.height;
          actualSelectorYTop = menuScreenHeight - 50.0;
          actualSelectorYBottom = menuScreenHeight;
          selectorOpacity = 0.0;
        } else {
          shouldRenderSelector = false;
        }
      }

      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: widget.background,
          color: widget.color,
        ),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              createDrawer(menuController),
              widget.animation && shouldRenderSelector
                  ? ItemSelector(
                      left: widget.direction == Direction.right
                          ? MediaQuery.of(context).size.width -
                              widget.maxSlideAmount
                          : 0,
                      selectorColor: selectorColor,
                      top: actualSelectorYTop,
                      bottom: actualSelectorYBottom,
                      opacity: selectorOpacity)
                  : Container(),
            ],
          ),
        ),
      );
    });
  }
}

class ItemSelector extends ImplicitlyAnimatedWidget {
  final double top;
  final double bottom;
  final double left;
  final double opacity;

  final Color selectorColor;

  ItemSelector({
    this.left,
    this.top,
    this.bottom,
    this.opacity,
    this.selectorColor,
  }) : super(duration: const Duration(milliseconds: 250));

  @override
  _ItemSelectorState createState() => _ItemSelectorState();
}

class _ItemSelectorState extends AnimatedWidgetBaseState<ItemSelector> {
  Tween<double> _topY;
  Tween<double> _bottomY;
  Tween<double> _opacity;

  @override
  void forEachTween(TweenVisitor visitor) {
    _topY = visitor(
      _topY,
      widget.top,
      (dynamic value) => Tween<double>(begin: value),
    );
    _bottomY = visitor(
      _bottomY,
      widget.bottom,
      (dynamic value) => Tween<double>(begin: value),
    );
    _opacity = visitor(
      _opacity,
      widget.opacity,
      (dynamic value) => Tween<double>(begin: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _topY.evaluate(animation),
      left: widget.left,
      child: Opacity(
        opacity: _opacity.evaluate(animation),
        child: Container(
          width: 5.0,
          height: _bottomY.evaluate(animation) - _topY.evaluate(animation),
          color: widget.selectorColor,
        ),
      ),
    );
  }
}

class AnimatedMenuListItem extends ImplicitlyAnimatedWidget {
  final _MenuListItem menuListItem;
  final MenuState menuState;
  final bool isSelected;
  final Duration duration;

  AnimatedMenuListItem({
    this.menuListItem,
    this.menuState,
    this.isSelected,
    this.duration,
    curve,
  }) : super(duration: duration, curve: curve);

  @override
  _AnimatedMenuListItemState createState() => _AnimatedMenuListItemState();
}

class _AnimatedMenuListItemState
    extends AnimatedWidgetBaseState<AnimatedMenuListItem> {
  final double closedSlidePosition = 200.0;
  final double openSlidePosition = 0.0;

  Tween<double> _translation;
  Tween<double> _opacity;

  updateSelectedRenderBox(bool useState) {
    final renderBox = context.findRenderObject() as RenderBox;
    if (renderBox != null && widget.isSelected) {
      (menuScreenKey.currentState as _MenuViewState)
          .setSelectedRenderBox(renderBox, useState);
    }
  }

  @override
  void forEachTween(TweenVisitor visitor) {
    var slide, opacity;

    switch (widget.menuState) {
      case MenuState.closed:
      case MenuState.closing:
        slide = closedSlidePosition;
        opacity = 0.0;
        break;
      case MenuState.open:
      case MenuState.opening:
        slide = openSlidePosition;
        opacity = 1.0;
        break;
    }

    _translation = visitor(
      _translation,
      slide,
      (dynamic value) => Tween<double>(begin: value),
    );

    _opacity = visitor(
      _opacity,
      opacity,
      (dynamic value) => Tween<double>(begin: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    updateSelectedRenderBox(false);

    return Opacity(
      opacity: _opacity.evaluate(animation),
      child: Transform(
        transform: Matrix4.translationValues(
          0.0,
          _translation.evaluate(animation),
          0.0,
        ),
        child: widget.menuListItem,
      ),
    );
  }
}

class _MenuListItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final bool drawBorder;
  final Function() onTap;
  final Color selectorColor;
  final TextStyle textStyle;
  final MenuView menuView;
  final Widget icon;
  final Direction direction;
  final double width;
  final EdgeInsets padding;

  _MenuListItem({
    this.title,
    this.isSelected,
    this.onTap,
    this.menuView,
    @required this.textStyle,
    @required this.selectorColor,
    this.icon,
    this.drawBorder,
    this.direction = Direction.right,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle _textStyle =
        textStyle.copyWith(color: isSelected ? selectorColor : textStyle.color);

    List<Widget> children = [];
    if (icon != null)
      children.add(Padding(
        padding: EdgeInsets.only(right: 12),
        child: IconTheme(
            data: IconThemeData(color: _textStyle.color), child: icon),
      ));
    children.add(
      Expanded(
        child: Container(
          child: Text(
            title,
            style: _textStyle,
          ),
        ),
        flex: 1,
      ),
    );
    return InkWell(
      splashColor: const Color(0x44000000),
      onTap: isSelected ? null : onTap,
      child: Container(
        width: width,
        alignment: Alignment.centerLeft,
        // padding: padding,
        decoration: drawBorder
            ? ShapeDecoration(
                shape: Border(
                  left: BorderSide(
                      color: isSelected ? selectorColor : Colors.transparent,
                      width: 5.0),
                ),
              )
            : null,
        child: Padding(
          padding: menuView.padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

class Menu {
  final List<MenuItem> items;

  Menu({
    this.items,
  });
}

class MenuItem<T> {
  final T id;
  final String title;
  final IconData icon;

  MenuItem({
    this.id,
    this.title,
    this.icon,
  });

  MenuItem<T> copyWith({
    T id,
    String title,
    IconData icon,
  }) {
    return MenuItem<T>(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon,
    );
  }
}