

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Detect special characters in a character vector of args
#'
#' This is implemented as a whitelist of characters to accept. The presence
#' of anything outside this whitelist is considered a 'special character'
#'
#' @param args character vector of args to check
#'
#' @return logical vector to match input 'args' set to TRUE if there are special
#'         characters in the individual arguments.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has_special_chars <- function(args) {
  # special_chars <- "[&;|<>$!]"
  match_not_allowed <- "[^-+=_.,:?*/~a-zA-Z0-9 \\\\[\\]\\{\\}\n\t]"
  grepl(match_not_allowed, args, perl=TRUE)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Detect special characters in a character vector of args
#'
#' @param args character vector of args to check
#'
#' @return logical vector to match input 'args' set to TRUE if there are file
#'         expansion characters in the individual arguments.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has_file_expansion <- function(args) {
  expansion_chars <- "[*\\[?]"
  grepl(expansion_chars, args, perl = TRUE)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Detect plain spaces in the args
#'
#' @param args character vector of args to check
#'
#' @return logical vector to match input 'args' set to TRUE if there are spaces
#'         in the individual arguments.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has_spaces <- function(args) {
  grepl(" ", args)
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Assert character vector is sane
#'
#' Zero-length vector allowed. No NAs allowed. Must be fewer than 1000 arguments
#' and fewer than 200000 characters
#'
#' @param args character vector of args to check
#'
#' @return logical TRUE if all test pass, otherwise through an error.
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
#' Escape any spaces in args e.g. in filenames
#'
#' @param args sane character vector of args. See \code{assert_sane_character_vector()}
#'
#' @return character vector with spaces escaped with a backslash.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
escape_spaces <- function(args) {
  gsub(" ", "\\\\ ", args)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Shell quote all arguments except for those which include bash filename expansion
#'
#' Filename expansion characters are \code{*}, \code{[} and \code{?}.  Regardless
#' of whether an arg contains file expansion characters or not, if it contains
#' any non-approved character it will be wrapped shQuote()
#'
#' @param args sane character vector of args. See \code{assert_sane_character_vector()}
#'
#' @return Apply shQuote() to all arguments.  Leave args with file expansion unquoted,
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
#' Run the given command the supplied arguments. Shell expansion of filenames is still performed.
#'
#' @param command Character scalar, the command to run
#' @param args character vector, arguments to the command
#' @param error_on_status Throw an error if the command returns a non-zero status?
#'        Default: TRUE
#' @param echo Echo the command to be run. Default: TRUE
#' @param timeout whole seconds for which to run before interrupting process.
#'        Default: 0 (no limit)
#'
#' @return list with 'status', 'stdout', 'stderr'
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
run <- function(command, args = NULL, error_on_status = TRUE, echo = FALSE, timeout = 10) {

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


  command_string <- paste0(c(command, args), collapse = " ")
  if (echo) {
    message(command_string)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Ignore any R warnings. Focus on shell errors instead
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The system is assumed to be running on a 'bash' compatible shell
# The 'figlet' command is the standard 'figlet' command
# The user only controls 'args'.
#
# How can this be easily broken by a malicious user
#   - who only has access to change 'args'
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (FALSE) {
  args <- c('hello *')
  cat(run('figlet', args, timeout = 10)$stdout)
}




