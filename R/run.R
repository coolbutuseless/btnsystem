

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Detect special characters in a character vector.
#'
#' This is implemented as a whitelist of characters to accept.
#' Anything not in the whitelist is considered a 'special character'.
#'
#' @param args Character vector of arguments to check.
#'
#' @return Logical vector. Elements are set to TRUE if there are special characters
#'         in the corresponding \code{args} element.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has_special_chars <- function(args) {
  # special_chars <- "[&;|<>$!]"
  match_not_allowed <- "[^-+=_.,:?*/~a-zA-Z0-9 \\\\[\\]\\{\\}\n\t]"
  grepl(match_not_allowed, args, perl=TRUE)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Detect special characters in a character vector.
#'
#' @param args Character vector of arguments to check.
#'
#' @return Logical vector. Elements are set to TRUE if there are file expansion characters
#'         in the corresponding \code{args} element.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has_file_expansion <- function(args) {
  expansion_chars <- "[*\\[?]"
  grepl(expansion_chars, args, perl = TRUE)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Detect plain spaces in a character vector.
#'
#' This function checks for plain ASCII space characters. It
#' ignores tab, newline and any other "whitespace" characters.
#'
#' @param args Character vector of arguments to check.
#'
#' @return >ogical vector. Elements are set to TRUE if there are spaces
#'         in the corresponding \code{args} element.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has_spaces <- function(args) {
  grepl(" ", args)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Assert character vector is sane.
#'
#' Zero-length vector allowed. No NAs allowed. Must be fewer than 1000 arguments
#' and fewer than 200000 characters.
#'
#' @param args Character vector of arguments to check.
#'
#' @return Logical value.  TRUE if all tests pass, otherwise throw an error.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assert_sane_character_vector <- function(args) {
  stopifnot(is.atomic(args))
  if (length(args) == 0) {return(invisible(TRUE))}
  stopifnot(is.character(args))
  stopifnot(length(args) < 1000)
  stopifnot(!anyNA(args))
  lens <- vapply(args, nchar, integer(1))
  stopifnot(sum(lens) < 200000)
  invisible(TRUE)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Escape any plain spaces.
#'
#' Usually only apply this to arguments which represent filenames and contain
#' filename expansion characters.
#'
#' @param args A sane character vector of arguments. See \code{assert_sane_character_vector()}
#'
#' @return Character vector with spaces escaped with a backslash.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
escape_spaces <- function(args) {
  gsub(" ", "\\\\ ", args)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Shell quote all arguments except for those which include bash filename expansion.
#'
#' Filename expansion characters are \code{*}, \code{[} and \code{?}.  Regardless
#' of whether an arg contains file expansion characters or not, if it contains
#' any non-approved character it will be wrapped in \code{shQuote()}
#'
#' @param args A sane character vector of arguments. See \code{assert_sane_character_vector()}
#'
#' @return Apply \code{shQuote()} to all arguments.  Leave args with file expansion unquoted,
#'         unless they contain special characters
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prepare_for_shell <- function(args) {
  file_expansions <- has_file_expansion(args)
  special_chars   <- has_special_chars(args)
  spaces          <- has_spaces(args)

  quote             <- special_chars | !file_expansions
  need_space_escape <- !quote

  args <- ifelse(special_chars | !file_expansions, shQuote(args), args)
  args[need_space_escape] <- escape_spaces(args[need_space_escape])

  args
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Run the given command with the supplied arguments.
#'
#' This is an alternate interface to the \code{system2()} command with more
#' safety checks to help mitigate some common security concerns.
#'
#' Shell expansion of filenames can still be used.
#'
#' This function is heavily modelled on \code{processx::run()}.
#'
#' @param command Character scalar, the command to run
#' @param args Character vector, arguments to the command
#' @param error_on_status Throw an error if the command returns a non-zero status?
#'        Default: TRUE
#' @param wd Working directory of the command. If NULL (default), the current working
#'        directory will be used.
#' @param echo_cmd Echo the command to be run. Default: FALSE
#' @param timeout Timeout for the command, in seconds.  If it is not finished before this,
#'        the command will be interupted.  Default: 10.  Use \code{timeout=0} to
#'        let the command run until completion.
#'
#' @return A list with components \itemize{
#' \item{status}{ - The exit status of the command.}
#' \item{stdout}{ - The standard output of the command, in a character scalar.}
#' \item{stderr}{ - The standard error of the command, in a character scalar.}
#' \item{string}{ - An equivalent string to the command which was executed}
#' }
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
run <- function(command, args = NULL, error_on_status = TRUE, wd = NULL,
                echo_cmd = FALSE, timeout = 10) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Tidy up the args. shell quote what we can, let the shell expand filenames
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  assert_sane_character_vector(args)
  args <- prepare_for_shell(args)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Location to store the stdout and stderr
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  stdout_file <- tempfile()
  stderr_file <- tempfile()

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Set the working directory if requested
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (!is.null(wd)) {
    start_dir <- getwd()
    on.exit(setwd(start_dir))
    setwd(wd)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Echo the command if requested
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  command_string <- paste0(c(command, args), collapse = " ")
  if (echo_cmd) {
    message(command_string)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Ignore any R warnings. Focus on shell errors instead
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  status <- NA_integer_
  suppressWarnings({
    status <- system2(command, args, stdout = stdout_file, stderr = stderr_file, timeout = timeout)
  })

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Read in the stdout/stderr to return to called
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  this_stdout <- trimws(paste0(readLines(stdout_file), collapse = "\n"))
  this_stderr <- trimws(paste0(readLines(stderr_file), collapse = "\n"))

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # We could cause an error to be raised if status != 0, or we could just
  # pass it back to the caller and let them decide how to handle.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (error_on_status && status != 0) {
    stop("run(): Error on Status = ", status, "\n", this_stderr)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Information about the run
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  list(
    status = status,
    stdout = this_stdout,
    stderr = this_stderr,
    string = command_string
  )
}


