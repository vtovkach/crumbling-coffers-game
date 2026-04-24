# Testing Plan: Core Mechanics & Game Flow
**Target Module:** Physics Boundaries and Global Match Management  
**Status:** Implementation Phase  

## 1. Overview
This document outlines the testing strategy for high-priority logic within the Godot project. The goal is to move away from scene-dependent testing (which can be unstable in isolated environments) toward robust API and class-level verification.

## 2. Feature: World Boundary Integrity
**Location:** `test_boundaries.gd`  
**Objective:** Ensure the Physics API correctly handles collisions and prevents tunneling (passing through geometry).

### Target Components
* **Class:** `CharacterBody2D` (Player) and `StaticBody2D` (Boundary)
* **API Calls:** `move_and_collide()`

### Test Case: High-Velocity Collision
* **Logic:** Instantiate a raw `CharacterBody2D`. Pass a motion vector that significantly exceeds the distance to a `WorldBoundaryShape2D`.
* **API Verification:** Capture the `KinematicCollision2D` object returned by `move_and_collide`.
* **Field Assertions:**
    * Assert `collision_info != null` (The API detected the hit).
    * Assert `collision_info.get_normal()` matches the boundary's surface normal.
    * Assert `player.global_position` is adjusted by the engine to stay outside the boundary.

## 3. Feature: Match Lifecycle Management
**Location:** `test_game_flow.gd`  
**Objective:** Verify the `MatchManager` Singleton handles time-sensitive state transitions and boundary conditions.

### Target Components
* **Class:** `MatchManager`
* **Target Methods:** `start_match()`, `_on_game_timer_timeout()`

### Test Case: Match Expiration State
* **Logic:** Manually manipulate the `time_left` field within the manager to simulate an edge case (1 second remaining).
* **Action:** Directly call the timeout handler `_on_game_timer_timeout()`.
* **Return/State Verification:**
    * Assert `MatchManager.time_left == 0`.
    * Assert `MatchManager.current_state == MatchState.ENDED`.
    * Verify that internal signals (like `match_ended`) are emitted.

## 4. Implementation Guidelines for the Team
* **No Scene Dependencies:** Instantiate raw classes using `.new()` to avoid texture-loading overhead and orphan node errors.
* **API Focus:** Every test must assert at least one **return object** or **field change** resulting from a method call.
* **Cleanup:** Utilize GUT's `add_child_autofree()` to ensure the SceneTree is cleared after every test execution.