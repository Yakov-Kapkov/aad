# Example pseudo-tests

Example: one project's shape, with the noise removed. One flow is shown; a change touching
several flows gets one such group per flow. Each scenario is a developed list item (shortened).

```
# Programming Challenge Instance test suite

## Flow: submit a challenge

Scenario 1: the executor calls the backend execute method
  challengeExecutor.execute(program, challengeInstance)

  expect(api.execute).calledOnceWith(challengeInstance.id, program)

Scenario 2: the executor verifies preconditions for the program code
  challengeExecutor.execute(program, challengeInstance)

  expect(conditionEvaluator.evaluate).calledOnceWith(program)

Scenario 3: the executor returns the result of the program execution
  result = challengeExecutor.execute(program, challengeInstance)

  expect(result.result).toBe('success')
```
