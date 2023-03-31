box::use(
  jsonlite[unserializeJSON, unbox],
  glue[glue],
  checkmate[test_string],
  shiny.telemetry[build_token],
  stringr[str_sub],
  logger[log_info, log_debug, log_error, log_warn],
)

box::use(
  api/logic/setup[data_storage],
  api/logic/token[validate_token, get_secret],
)

#' Handler to insert data to the data storage provider
#'
#' @param data seriealizedJSON with an R list object
#' @param token string with signature of the message
#' @param id string with identification of which secret to use
#' @param bucket string that identifies which bucket to save data to
#' @export
handler <- function(data, token, id, bucket){

  log_debug('@post /{bucket} triggered')

  values <- tryCatch ({
    unserializeJSON(data)
  }, error = function(err) {
    log_error("Couldn't serialize json")
    "Couldn't serialize json"
  })

  if (test_string(values)) {
    msg <- glue("Bad request at {Sys.time()}")
    return(list(status = 400, error = unbox(msg)))
  }

  is_token_valid <- validate_token(values, token, id)

  if (isFALSE(is_token_valid)) {
    msg <- glue("Invalid token at {Sys.time()}")
    log_warn(msg)
    calculated_token <- build_token(values, secret = get_secret(id)) |>
      str_sub(end = 8)
    log_debug(
      "Received token {str_sub(token, end = 8)} != ",
      "{calculated_token}"
    )
    return(list(status = 401, error = unbox(msg)))
  }

  data_storage$insert(
    values,
    add_username = FALSE,
    force_params = FALSE,
    bucket = bucket
  )

  msg <- glue::glue("Ok at {Sys.time()}")

  return(list(status = 200, success = unbox(msg)))
}