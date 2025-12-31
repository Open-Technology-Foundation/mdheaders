# Error Test Fixture

This file tests error handling edge cases.

## Header With Space

Normal header with proper space after #.

##NoSpaceHeader

This header has no space after ##.

###AlsoNoSpace

Another header without space.

## Indented Fence Test

  ```bash
  # This fence is indented with 2 spaces
  echo "indented"
  ```

## Nested Fence Scenario

~~~markdown
# Header inside tilde block
```
Backticks inside tildes
```
~~~

## Unclosed Block

This section has a code block that never closes.

```python
# This block is intentionally not closed
def broken():
    pass

#fin
