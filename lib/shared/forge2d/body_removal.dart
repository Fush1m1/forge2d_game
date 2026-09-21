import 'package:flame_forge2d/flame_forge2d.dart';

/// Destroys [component]'s Forge2D body if it hasn't mounted yet, working
/// around a Forge2D body leak: Flame only calls [Component.onRemove] for a
/// component that was previously mounted (see Component's own doc
/// comment), so [BodyComponent.onRemove] — which destroys the Forge2D
/// body — never runs for one that's removed before it ever mounted. This
/// can happen to a level built while the engine is about to be paused (its
/// components sit loaded-but-not-mounted until the engine resumes, since
/// mounting only happens as part of the per-frame update loop), or to a
/// ball that merges on the very frame it was dropped, before it's had a
/// chance to mount. Without this, removing either would leak an
/// invisible-but-solid phantom body. Call this before
/// `removeFromParent()`, which makes its own (otherwise-skipped) destroy
/// path a no-op for the normal, already-mounted case.
void destroyBodyIfUnmounted(Forge2DWorld world, BodyComponent component) {
  if (component.isLoaded && !component.isMounted) {
    world.destroyBody(component.body);
  }
}

/// Removes [component] from its parent, first destroying its Forge2D body
/// if it never mounted — see [destroyBodyIfUnmounted].
void removeBodyComponent(Forge2DWorld world, BodyComponent component) {
  destroyBodyIfUnmounted(world, component);
  component.removeFromParent();
}
