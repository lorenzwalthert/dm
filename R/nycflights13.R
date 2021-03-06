#' Creates a [`dm`] object for the \pkg{nycflights13} data
#'
#' @description Creates an example [`dm`] object from the tables in \pkg{nycflights13},
#' along with the references.
#' See [nycflights13::flights] for a description of the data.
#' As described in [nycflights13::planes], the relationship
#' between the `flights` table and the `planes` tables is "weak", it does not satisfy
#' data integrity constraints.
#'
#' @param cycle Boolean.
#'   If `FALSE` (default), only one foreign key relation
#'   (from `flights$origin` to `airports$faa`) between the `flights` table and the `airports` table is
#'   established.
#'   If `TRUE`, a `dm` object with a double reference
#'   between those tables will be produced.
#' @param color Boolean, if `TRUE` (default), the resulting `dm` object will have
#'   colors assigned to different tables for visualization with `dm_draw()`
#'
#' @return A `dm` object consisting of {nycflights13} tables, complete with primary and foreign keys and optionally colored.
#'
#' @export
#' @examples
#' if (rlang::is_installed("nycflights13")) {
#'   dm_nycflights13() %>%
#'     dm_draw()
#' }
dm_nycflights13 <- nse(function(cycle = FALSE, color = TRUE) {
  dm <-
    dm_from_src(
      src_df("nycflights13")
    ) %>%
    dm_add_pk(planes, tailnum) %>%
    dm_add_pk(airlines, carrier) %>%
    dm_add_pk(airports, faa) %>%
    dm_add_fk(flights, tailnum, planes, check = FALSE) %>%
    dm_add_fk(flights, carrier, airlines) %>%
    dm_add_fk(flights, origin, airports)

  if (color) {
    dm <-
      dm %>%
      dm_set_colors(
        "#5B9BD5" = flights,
        "#ED7D31" = starts_with("air"),
        "#ED7D31" = planes,
        "#70AD47" = weather
      )
  }

  if (cycle) {
    dm <-
      dm %>%
      dm_add_fk(flights, dest, airports, check = FALSE)
  }

  dm
})
