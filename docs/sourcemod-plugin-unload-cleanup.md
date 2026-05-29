# SourceMod Plugin Unload Cleanup Guide

## Purpose

This note documents a practical cleanup policy for SourceMod plugins so the same criteria can be reused across projects.

The goal is to answer:

- what SourceMod cleans automatically on plugin unload
- what a plugin should still clean explicitly
- how small `OnPluginEnd()` should be

## What SourceMod Cleans Automatically

On plugin unload, SourceMod already cleans a large part of plugin-owned runtime state.

This includes, in general:

- handles owned by the plugin
- timers owned by the plugin
- ADT containers such as:
  - `StringMap`
  - `ArrayList`
  - `DataPack`
- normal plugin memory and globals

Practical implication:

- `OnPluginEnd()` is **not required** just to avoid basic handle leaks.
- You do **not** need to manually free every handle purely for memory safety.

## What Should Still Be Cleaned Explicitly

Even with automatic cleanup, explicit teardown is still useful in some cases.

Keep explicit cleanup for:

- manual hooks from extensions or engine helpers
  - `SDKHook`
  - `SDKUnhook`
  - similar explicit hook registration APIs
- state that should be detached deterministically before unload
- integrations that are safer with a clear shutdown order
- external side effects that are not just memory

Typical examples:

- unhooking `SDKHook_OnTakeDamage`
- unhooking `SDKHook_TraceAttack`
- unhooking entity/client hooks installed manually
- stopping custom background logic if it depends on explicit teardown

## What Is Usually Redundant in `OnPluginEnd()`

These are often unnecessary on unload:

- resetting large in-memory arrays only for cleanliness
- clearing event caches that will disappear with the plugin anyway
- calling broad `ResetAll()` routines just to zero data
- manually destroying every ADT handle only for leak prevention

This cleanup is usually harmless, but redundant.

## Recommended Policy

Use this rule:

- **automatic unload cleanup handles memory ownership**
- **`OnPluginEnd()` handles explicit teardown semantics**

In practice:

### Keep in `OnPluginEnd()`

- explicit `SDKUnhook` calls
- explicit detach/shutdown of systems with manual registration
- optional release of a few important global containers if that improves clarity

### Avoid in `OnPluginEnd()`

- bulk reset logic whose only purpose is zeroing state
- map-end style reset flows reused on unload without a real reason
- large teardown blocks that duplicate SourceMod ownership cleanup

## Minimal `OnPluginEnd()` Template

```sourcepawn
public void OnPluginEnd()
{
    Runtime_Shutdown();
    Hooks_Shutdown();
}
```

Where:

- `Runtime_Shutdown()` only handles things that need explicit detach
- `Hooks_Shutdown()` unhooks manual hooks

If a project does not install manual hooks or external registrations, `OnPluginEnd()` can legitimately stay empty or be omitted.

## Good Project Structure

Prefer separating cleanup intent by subsystem:

- `Boss_Shutdown()`
- `Detect_Shutdown()`
- `Stats_Shutdown()`
- `Hooks_Shutdown()`

Each shutdown function should do only what is unload-specific.

Avoid calling generic reset functions unless they are also the correct unload behavior.

## Decision Checklist

Before adding something to `OnPluginEnd()`, ask:

1. Is this cleaning memory that SourceMod already owns?
2. Is this undoing a manual registration or hook?
3. Does this prevent a real unload-time side effect?
4. Is this just a reset routine copied from map-end logic?

If the answer is:

- `1=yes` and `2=no` and `3=no`
  - usually skip it
- `2=yes`
  - keep it
- `3=yes`
  - keep it
- `4=yes`
  - usually remove or split it

## Recommended Default

For most SourceMod plugins:

- keep `OnPluginEnd()` small
- unhook explicit hooks
- detach external systems
- do not overuse full-state reset logic

That gives the cleanest balance between:

- correctness
- simplicity
- not fighting SourceMod's automatic cleanup

## References

- AlliedModders Wiki: Introduction to SourceMod Plugins  
  https://wiki.alliedmods.net/Introduction_to_SourceMod_Plugins

- AlliedModders Wiki: Timers (SourceMod Scripting)  
  https://wiki.alliedmods.net/Timers_%28SourceMod_Scripting%29

- AlliedModders Wiki: Handles (SourceMod Scripting)  
  https://wiki.alliedmods.net/Handles_%28SourceMod_Scripting%29
