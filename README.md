
<!-- README.md is generated from README.Rmd. Please edit that file -->

# btnsystem - a safer `system2()` <img src="man/figures/logo.png" align="right" height=230/>

<!-- badges: start -->

![](http://img.shields.io/badge/cool-useless-green.svg)
![](http://img.shields.io/badge/button-verse-blue.svg)
<!-- badges: end -->

`btnsystem` provides a safer version of `system2()` that still allows
for some shell features like filename expansion (e.g. with tilde, or
’\*’).

It achieves this by using `shQuote()` on all arguments except those
which contain a file expansion character (as long as no other special
characters are present)

The **btn** in `btnsystem` is pronounced “*button*” and stands for
“better than nothing”.`btnsystem` is a part of the ButtonVerse.

#### Am I on a fool’s errand? Can you break this idea and let me know?

## Installation

You can install btnsystem from
[CRAN](https://github.com/coolbutuseless/btnsystem) with:

``` r
# install.packages('remotes')
remotes::install_github("coolbutuseless/btnsystem")
```

## The problem with built-in `system()` and `system2()`: Multiple commands in a single call

It’s easy to get built-in `system2()` to execute arbitrary commands even
if a user only controls the `args` for a given comment.

In the following, the intent was to only run the ‘ls’ command, but it is
trivial to run any other command after this by setting an appropriate
argument.

``` r
command <- 'ls'
args    <- c('/tmp/crap.png ; echo "You just got hacked!"')

system2(command, args, stdout = TRUE)
```

``` 
   [1] "You just got hacked!"
```

## How `{processx}` avoids the issue of multiple commands

`processx` avoids this issue by avoiding the shell altogether and
executing the command directly via your operating system. This ensures
that only the one command will be run at any call e..g

In the following it can be seen that running the command via processx
will cause an error because it cannot find the literal file
`/tmp/crap.png ; echo "You just got hacked!"`

``` r
command <- 'ls'
args    <- c('/tmp/crap.png ; echo "You just got hacked!"')

processx::run(command, args, error_on_status = FALSE)
```

``` 
   $status
   [1] 1
   
   $stdout
   [1] ""
   
   $stderr
   [1] "ls: /tmp/crap.png ; echo \"You just got hacked!\": No such file or directory\n"
   
   $timeout
   [1] FALSE
```

## Why not `{processx}`?

Since `processx` avoids using the shell altogether it loses out on some
nice shell features like filename expansion (using `*`, `?` and others)
and tilde-expansion to access a user’s home directory.

So call using filename expansion with `*` will work correctly in
`system2()` but fail in `processx::run`. The following calls should both
detect 2 markdown files.

``` r
system2('ls', '*.md', stdout = TRUE)
```

``` 
   [1] "NEWS.md"   "README.md"
```

``` r
processx::run('ls', '*.md', error_on_status = FALSE)
```

``` 
   $status
   [1] 1
   
   $stdout
   [1] ""
   
   $stderr
   [1] "ls: *.md: No such file or directory\n"
   
   $timeout
   [1] FALSE
```

## `btnsystem` solution

The approach of `btnsystem::run()` is to wrap the built-in `system2()`
call, and pre-process the arguments to the command:

1.  If an arg contains a file expansion character (`*`, `?`, `[`) and no
    other special characters, then leave it as-is.
      - If it also contains spaces, then replace them with escaped
        spaces i.e. `\`
2.  All other arguments are wrapped in `shQuote()`

## `btnsystem` in action

`btnsystem` allows for both shell filename expansion, and protection
against running multiple commands, while still having special characters
which everyting wrapped in `shQuote()` to avoid shenanigans.

``` r
btnsystem::run('ls', '*.md', echo = TRUE)
```

``` 
   ls *.md
```

``` 
   $status
   [1] 0
   
   $stdout
   [1] "NEWS.md\nREADME.md"
   
   $stderr
   [1] ""
   
   $string
   [1] "ls *.md"
```

``` r
btnsystem::run('ls', '; echo "hacked"', echo = TRUE, error_on_status = FALSE)
```

``` 
   ls '; echo "hacked"'
```

``` 
   $status
   [1] 1
   
   $stdout
   [1] ""
   
   $stderr
   [1] "ls: ; echo \"hacked\": No such file or directory"
   
   $string
   [1] "ls '; echo \"hacked\"'"
```

``` r
res <- btnsystem::run('figlet', 'Stuff & Thing;', echo = TRUE)
```

``` 
   figlet 'Stuff & Thing;'
```

``` r
cat(res$stdout)
```

``` 
   ____  _          __  __    ___     _____ _     _               
   / ___|| |_ _   _ / _|/ _|  ( _ )   |_   _| |__ (_)_ __   __ _ _ 
   \___ \| __| | | | |_| |_   / _ \/\   | | | '_ \| | '_ \ / _` (_)
    ___) | |_| |_| |  _|  _| | (_>  <   | | | | | | | | | | (_| |_ 
   |____/ \__|\__,_|_| |_|    \___/\/   |_| |_| |_|_|_| |_|\__, ( )
                                                           |___/|/
```

## Corner cases which `btnsystem` will not accept.

There are some casualties to the strictness of this approach.

Arguments with ampersands, semicolons or other special characters,
cannot also use a file expansion character.

E.g. the following will not behave as a true shell would behave:
`btnsystem::run('ls', 'this & that image.*')`.

Because there is a special character in the argument string (`&`) the
argument is quoted with `shQuote()` so the filename expansion (`*`) is
never processed in the shell.

## Shakedown

Can you cause the following `btnsystem::run()` command to perform
something unexpected?

Assume that:

  - the user does **not** control the ‘command’
  - the users only input is via ‘args’

<!-- end list -->

``` r
command <- 'figlet'
args    <- c('-w', '40', 'hello there')

res <- btnsystem::run('figlet', args, timeout = 10)
cat(res$stdout)
```

``` 
   _          _ _       
   | |__   ___| | | ___  
   | '_ \ / _ \ | |/ _ \ 
   | | | |  __/ | | (_) |
   |_| |_|\___|_|_|\___/ 
                         
    _   _                   
   | |_| |__   ___ _ __ ___ 
   | __| '_ \ / _ \ '__/ _ \
   | |_| | | |  __/ | |  __/
    \__|_| |_|\___|_|  \___|
```
