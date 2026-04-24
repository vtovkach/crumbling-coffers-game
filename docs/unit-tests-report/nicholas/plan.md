## Unit Testing Plan

Goals 

- Move all of my tests added on "tests" branch to development branch

- Update those old tests to match hundreds of commits of new logic

- Replace "player" with "controllableplayer" in relevant tests

10+ tests involved; I name 3 here (for assignment):
- test_input_leftandright(): Directions should cancel out
- test_inputless_stop(): Directionless player should slow down due to friction
- test_push_directionless(): When pushed in no direction, player should not move

### How to run: Tests are run with GUT (Godot Unit Testing).