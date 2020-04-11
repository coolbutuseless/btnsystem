

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Detect special characters in a character vector of args
#'
#' @param args character vector of args to check
#'
#' @return logical vector to match input 'args' set to TRUE if there are special
#'         characters in the individual arguments.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has_special_chars <- function(args) {
  match_disallowed <- "[^-=_.,:?*/~a-zA-Z0-9 \\\\[\\]\\{\\}\n\t]"
  grepl(match_disallowed, args, perl=TRUE)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Raise an error if any of the args contain special characters
#' @param args character vector of args to check
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assert_no_special_chars <- function(args) {
  specials <- has_special_chars(args)
  if (any(specials)) {
    stop("The following arguments have disallowed special characters: ",
         deparse(args[specials]))
  }
  invisible(TRUE)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Assert character vector is sane
#'
#' Zero-length vector allowed.
#' No NAs allowed.
#'
#' @param args character vector of args to check
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assert_sane_character_vector <- function(args) {
  if (length(args) == 0) {return()}
  stopifnot(is.character(args))
  stopifnot(length(args) < 1000)
  stopifnot(!anyNA(args))
  lens <- vapply(args, nchar, integer(1))
  stopifnot(sum(lens) < 20000)
  invisible(TRUE)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Check args for sanity
#'
#' @param args character vector of args to check
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
check_args <- function(args) {
  assert_sane_character_vector(args)
  assert_no_special_chars(args)
  invisible(TRUE)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Escape any spaces in args e.g. in filenames
#'
#' @param args sane character vector of args. See \code{assert_sane_character_vector()}
#'
#' @return character vector with spaces escaped with a backslash.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
escape_spaces_in_args <- function(args) {
  gsub("\\s", "\\\\ ", args)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Shell quote all arguments except for those which include bash filename expansion
#'
#' Filename expansion characters are \code{*}, \code{[} and \code{?}
#'
#' @param args sane character vector of args. See \code{assert_sane_character_vector()}
#'
#' @return Apply shQuote() to all arguments which do not look like they do
#'         not contain base filename expansion characters
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
shell_quote <- function(args) {
  has_file_expansion <- grepl("[*\\[?]", args, perl = TRUE)
  ifelse(has_file_expansion, args, shQuote(args))
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
run <- function(command, args = NULL, error_on_status = TRUE, echo = TRUE, timeout = 10) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Tidy up the args. shell quote what we can, let the shell expand filenames
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  check_args(args)
  args <- escape_spaces_in_args(args)
  args <- shell_quote(args)

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
    stderr = this_stderr
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
  args <- c('hello')
  run('figlet', args, timeout = 10)
}




