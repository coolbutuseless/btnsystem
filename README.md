
<!-- README.md is generated from README.Rmd. Please edit that file -->

# btnsystem <img src="man/figures/logo.png" align="right" height=230/>

<!-- badges: start -->

![](http://img.shields.io/badge/cool-useless-green.svg)
![](http://img.shields.io/badge/button-verse-blue.svg)
<!-- badges: end -->

The goal of btnsystem is to provide a safer and tidier version of system
which still allows for some shell features like filename expansion
(e.g. with tilde, or ’\*’).

#### Am I on a fool’s errand? Can you break this idea and let me know?

## Installation

You can install btnsystem from
[CRAN](https://github.com/coolbutuseless/btnsystem) with:

``` r
# install.packages('remotes')
devtools::install_github("btnsystem")
```

## The problem with built-in `system()` and `system2()`

Easy to get built-in `system2()` to execute arbitrary commands even if
they only control the `args` and not the `command`.

In the following, the intent was to only run the ‘ls’ command, but it is
trivial to run any other command after this by setting an appropriate
argument.

``` r
command <- 'ls'
args    <- c('/tmp/crap.png ; echo "If you see this text, then any arbitrary command could have been run"')

system2(command, args, stdout = TRUE)
#> [1] "If you see this text, then any arbitrary command could have been run"
```

## Why not `{processx}`?

My current requirement is that filename expansion in the shell can still
occur i.e. `ls *.md` should list all the md files. However, because of
the way `{processx}` executes the command without using the shell, shell
expansion never occurs and an the following code would try and list
files with a verbatim name of ’\*.md’

A call using `system2()` expands the filenames, but a call to
`processx::run` does not.

``` r
system2('ls', '*.md')
processx::run('ls', '*.md', error_on_status = FALSE)
```

## Shake down

Can you cause the following `btnsystem::run()` command to perform
something unexpected?

Assume that:

  - the user does **not** control the ‘command’
  - the users only input is via ‘args’

<!-- end list -->

``` r
command <- 'figlet'
args    <- c('-w', '40', 'hello', 'there')

res <- btnsystem::run('figlet', args, timeout = 10)
#> figlet '-w' '40' 'hello' 'there'
cat(res$stdout)
#> _          _ _       
#> | |__   ___| | | ___  
#> | '_ \ / _ \ | |/ _ \ 
#> | | | |  __/ | | (_) |
#> |_| |_|\___|_|_|\___/ 
#>                       
#>  _   _                   
#> | |_| |__   ___ _ __ ___ 
#> | __| '_ \ / _ \ '__/ _ \
#> | |_| | | |  __/ | |  __/
#>  \__|_| |_|\___|_|  \___|
```
