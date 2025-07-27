# style guide

## naming conventions

### files
- file names are in *snake_case*

### types
- structs: *Ada_Case*
- enum type: *Ada_Case*
- enum members: *UPPER_SNAKE_CASE*

### functions
- functions: *snake_case*

### variables
- muts:   *snake_case*
- consts: *UPPER_SNAKE_CASE*
- local / public variables: *context*
    > NOTE: a case of *context* means you use what would apply from previously described cases
    > so for example, a local const would be in *UPPER_SNAKE_CASE*
    > while a local mut would be in *snake_case*
- private variables: *context* prefixed with "_"
- public only to folder scope: *context* prefixed with "__"
    > like how handle is public to all eng packages but not to outside ones*

### packages
- package names should not be plural
- folder name: *snake_case*
- package name: same as folder name*
    > if there is a conflict like with time, name it whatever the fuck you want
    > or if it is generally used under a different (full) name, use that

---

## spacing and layout
- indentation: 4 spaces, no tabs
- prefer `do` instead of brackets for single line unless deemed too long
- brackets on the same line
```odin
// do this
if condition {

}

// not this
if condition 
{

}
```

---

## imports
- prefer to use using
    > when using using, generally you should not alias the import name, unless it is a special case like core -> eng
- if you only use the import a very small amount of times, prefer not to alias it
    > this can be ignored for packages that should usually be aliased
- general order:
    - non aliased before aliased
    - go in order of name length
    - go in order of least nested to most nested path
    - group similar file paths together
        > if same length and path, group by time added to list of imports
- order:
    - packages from same path (engine packages for eng, user packages for src)
    - core packages
    - engine packages
        - engine core
        - engine stuff
    - library packages
        - non engine
        - engine
    - vendor packages

---

## formatting
- maximum amount of blank lines: two

### functions
- keep similar functions close together
- explicit overloads should be one line if less than 3 functions
- explicit overload should be after the overloaded functions
- keep at minimum one blank line between functions
    > ignored when the functions are literally one line (not just the contents)
- keep at minimum one blank line between functions and explicit overloads
- explicit overloads have to have at minimum two blank lines after them
- in rendering functions, if you have an overload that uses floats for positioning, you must have that as a seperate overload prefixed by 'f' 
    > UNLESS the only type used for positioning is a float (in that case you're weird)

#### parameters
- group similar parameters together by removing the space inbetween them
```odin
rect(x,y, w,h, color)
```

### commas
- no trailing commas UNLESS the file is an auto generated file, in which it is encouraged

### control flow
- if you have an if statement chain with else if, space out the first condition to be on the same spot as the others
- switch statements are preferred to if statements
- switch statement cases should be on the same indentation as the switch
    > switch val {
    > case val:
    >     // do something
    > }

### variables
- heres a little example for how to do variables
```odin
var := val
var :: val
var: type = val
var :type: val
var: type ;; { /* definition func */ }
```

---

## comments
- please refrain from using comments, unless it fits one of these reasons:
    - it is funny
    - the thing it explains is weird
    - the comment is for a function that has data that needs to be freed (then comment is required)
- function comments must use `//` and have ***zero*** blank lines between it and the function
    > this is to make the commenter refrain from being too yappity

---

# conclusion
- if you want to be consistent with the style of the engine, please use this
- otherwise, i literally do not care about your style
    > if you have a pull request though, please atleast follow the parts of the style guide
    > that make it consistent for the user to use the engine
