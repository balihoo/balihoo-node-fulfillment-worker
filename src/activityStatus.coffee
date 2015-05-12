module.exports =
  # Complete
    success: 'SUCCESS'

  # Fail
    invalid: 'INVALID' # A retry without fixing the input will not work
    fatal: 'FATAL' # A retry with the current input will not work

  # Cancel
    error: 'ERROR' # An error was encountered, retry might work
    defer: 'DEFER' # Result not yet available, retry