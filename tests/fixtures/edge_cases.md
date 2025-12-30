# Minimum Level Header

This tests edge cases.

###### Maximum Level Header

Already at H6.

## Normal Header

```markdown
# This looks like a header but it's in a code block
## So is this
### And this
```

### Mixed Fences

```
# Code block with backticks
```

~~~
# Code block with tildes
~~~

#### Unclosed Fence Test

This section is fine.

```
This code block will be closed properly
```

##### Deep Header

Testing H5 to H6 upgrade.

###### Already Maximum

Cannot upgrade further.

# Back to H1

Cannot downgrade this one further.

#fin
