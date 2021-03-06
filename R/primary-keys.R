#' Add/remove a primary key
#'
#' @description `dm_add_pk()` marks the specified columns as the primary key of the specified table.
#' If `check == TRUE`, then it will first check if
#' the given combination of columns is a unique key of the table.
#' If `force == TRUE`, the function will replace an already
#' set key.
#'
#' `dm_rm_pk()` removes a primary key from a table and leaves the [`dm`] object otherwise unaltered.
#' Foreign keys that point to the table from other tables, can be optionally removed as well.
#'
#' @section Compound keys:
#'
#' Currently, keys consisting of more than one column are not supported.
#' [This feature](https://github.com/krlmlr/dm/issues/3) is planned for dm 0.2.0.
#' The syntax of these functions will be extended but will remain compatible
#' with current semantics.
#'
#' @param dm A `dm` object.
#' @param table A table in the `dm`.
#' @param columns Table columns, unquoted.
#' @param check Boolean, if `TRUE`, a check is made if the combination of columns is a unique key of the table.
#' @param force Boolean, if `FALSE` (default), an error will be thrown if there is already a primary key
#'   set for this table.
#'   If `TRUE`, a potential old `pk` is deleted before setting a new one.
#'
#' @family primary key functions
#'
#' @return For `dm_add_pk()`: An updated `dm` with an additional primary key.
#'
#' @export
#' @examples
#' nycflights_dm <- dm_from_src(dplyr::src_df(pkg = "nycflights13"))
#' nycflights_dm %>%
#'   dm_draw()
#'
#' # the following works
#' nycflights_dm %>%
#'   dm_add_pk(planes, tailnum) %>%
#'   dm_add_pk(airports, faa, check = TRUE) %>%
#'   dm_draw()
#'
#' # the following does not work (throws an error)
#' try(
#'   nycflights_dm %>%
#'     dm_add_pk(planes, manufacturer, check = TRUE)
#' )
dm_add_pk <- function(dm, table, columns, check = FALSE, force = FALSE) {
  check_not_zoomed(dm)
  table_name <- as_name(ensym(table))

  check_correct_input(dm, table_name)

  col_expr <- ensym(columns)
  col_name <- as_name(col_expr)
  check_col_input(dm, table_name, col_name)

  if (check) {
    table_from_dm <- dm_get_filtered_table(dm, table_name)
    check_key(table_from_dm, !!col_expr)
  }

  dm_add_pk_impl(dm, table_name, col_name, force)
}

# both "table" and "column" must be characters
# in {datamodelr}, a primary key may consist of more than one columns
# a key will be added, regardless of whether it is a unique key or not; not to be exported
dm_add_pk_impl <- function(dm, table, column, force) {
  def <- dm_get_def(dm)
  i <- which(def$table == table)

  if (!force && NROW(def$pks[[i]]) > 0) {
    abort_key_set_force_false(table)
  }

  def$pks[[which(def$table == table)]] <- tibble(column = !!list(column))

  new_dm3(def)
}

#' Check for primary key
#'
#' @description `dm_has_pk()` checks if a given table has columns marked as its primary key.
#'
#' @inheritParams dm_add_pk
#'
#' @family primary key functions
#'
#' @return A logical value: `TRUE` if the given table has a primary key, `FALSE` otherwise.
#'
#' @examples
#' dm_nycflights13() %>%
#'   dm_has_pk(flights)
#' dm_nycflights13() %>%
#'   dm_has_pk(planes)
#' @export
dm_has_pk <- function(dm, table) {
  check_not_zoomed(dm)
  has_length(dm_get_pk(dm, {{ table }}))
}

#' Primary key column names
#'
#' @description `dm_get_pk()` returns the names of the
#' columns marked as primary key of a table of a [`dm`] object.
#' If no primary key is
#' set for the table, an empty character vector is returned.
#'
#' @section Compound keys and multiple primary keys:
#'
#' Currently, keys consisting of more than one column are not supported.
#' [This feature](https://github.com/krlmlr/dm/issues/3) is planned for dm 0.2.0.
#' Therefore the function may return vectors of length greater than one in the future.
#'
#' Similarly, each table currently can have only one primary key.
#' This restriction may be lifted in the future.
#' For this reason, and for symmetry with `dm_get_fk()`,
#' this function returns a slit of character vectors.
#'
#' @family primary key functions
#'
#' @return A list with character vectors with the column name(s) of the
#'   primary keys of `table`.
#'
#' @inheritParams dm_add_pk
#'
#' @examples
#' dm_nycflights13() %>%
#'   dm_get_pk(flights)
#' dm_nycflights13() %>%
#'   dm_get_pk(planes)
#' @export
dm_get_pk <- function(dm, table) {
  check_not_zoomed(dm)
  table_name <- as_name(ensym(table))
  check_correct_input(dm, table_name)
  new_keys(dm_get_pk_impl(dm, table_name))
}

dm_get_pk_impl <- function(dm, table_name) {
  pks <- dm_get_data_model_pks(dm)
  pks$column[pks$table == table_name]
}

#' Get all primary keys of a [`dm`] object
#'
#' @description `dm_get_all_pks()` checks the `dm` object for set primary keys and
#' returns the tables, the respective primary key columns and their classes.
#'
#' @section Compound keys:
#'
#' Currently, keys consisting of more than one column are not supported.
#' [This feature](https://github.com/krlmlr/dm/issues/3) is planned for dm 0.2.0.
#' Therefore the `pk_cols` column may contain vectors of length greater than one.
#'
#' @family primary key functions
#'
#' @inheritParams dm_add_pk
#'
#' @return A tibble with the following columns:
#'   \describe{
#'     \item{`table`}{table name,}
#'     \item{`pk_cols`}{column name(s) of primary key.}
#'   }
#'
#' @export
#' @examples
#' dm_nycflights13() %>%
#'   dm_get_all_pks()
dm_get_all_pks <- nse(function(dm) {
  check_not_zoomed(dm)
  dm_get_all_pks_impl(dm) %>%
    mutate(pk_col = new_keys(pk_col))
})

dm_get_all_pks_impl <- function(dm) {
  dm_get_data_model_pks(dm) %>%
    select(table = table, pk_col = column)
}


#' Remove a primary key from a table in a [`dm`] object
#'
#' @rdname dm_add_pk
#'
#' @param rm_referencing_fks Boolean: if `FALSE` (default), will throw an error if
#'   there are foreign keys addressing the primary key that is to be removed.
#'   If `TRUE`, the function will
#'   remove, in addition to the primary key of the `table` argument, also all foreign key constraints
#'   that are pointing to it.
#'
#' @return For `dm_rm_pk()`: An updated `dm` without the indicated primary key.
#'
#' @examples
#'
#' dm_nycflights13() %>%
#'   dm_rm_pk(airports, rm_referencing_fks = TRUE) %>%
#'   dm_draw()
#' @export
dm_rm_pk <- function(dm, table, rm_referencing_fks = FALSE) {
  check_not_zoomed(dm)
  table_name <- as_name(ensym(table))
  check_correct_input(dm, table_name)

  def <- dm_get_def(dm)

  if (!rm_referencing_fks && dm_is_referenced(dm, !!table_name)) {
    affected <- dm_get_referencing_tables(dm, !!table_name)
    abort_first_rm_fks(table_name, affected)
  }
  def$pks[def$table == table_name] <- list(new_pk())
  def$fks[def$table == table_name] <- list(new_fk())

  new_dm3(def)
}


#' Primary key candidate
#'
#' @description \lifecycle{questioning}
#'
#' `enum_pk_candidates()` checks for each column of a
#' table if the column contains only unique values, and is thus
#' a suitable candidate for a primary key of the table.
#'
#' @return A tibble with the following columns:
#'   \describe{
#'     \item{`columns`}{columns of `table`,}
#'     \item{`candidate`}{boolean: are these columns a candidate for a primary key,}
#'     \item{`why`}{if not a candidate for a primary key column, explanation for this.}
#'   }
#'
#' @section Life cycle:
#' These functions are marked "questioning" because we are not yet sure about
#' the interface, in particular if we need both `dm_enum...()` and `enum...()`
#' variants.
#' Changing the interface later seems harmless because these functions are
#' most likely used interactively.
#'
#' @export
#' @examples
#' nycflights13::flights %>%
#'   enum_pk_candidates()
enum_pk_candidates <- nse(function(table) {
  # a list of ayes and noes:
  if (is_dm(table) && is_zoomed(table)) table <- get_zoomed_tbl(table)

  enum_pk_candidates_impl(table) %>%
    rename(columns = column) %>%
    mutate(columns = new_keys(columns))
})

#' @description `dm_enum_pk_candidates()` performs these checks
#' for a table in a [dm] object.
#'
#' @family primary key functions
#'
#' @inheritParams dm_add_pk
#'
#' @rdname enum_pk_candidates
#' @export
#' @examples
#'
#' dm_nycflights13() %>%
#'   dm_enum_pk_candidates(airports)
dm_enum_pk_candidates <- nse(function(dm, table) {
  check_not_zoomed(dm)
  # FIXME: with "direct" filter maybe no check necessary: but do we want to check
  # for tables retrieved with `tbl()` or with `dm_get_tables()[[table_name]]`
  check_no_filter(dm)

  table_name <- as_name(ensym(table))
  check_correct_input(dm, table_name)

  table <- dm_get_tables_impl(dm)[[table_name]]
  enum_pk_candidates_impl(table) %>%
    rename(columns = column) %>%
    mutate(columns = new_keys(columns))
})

enum_pk_candidates_impl <- function(table) {
  map(set_names(colnames(table)), function(x) is_unique_key(table, {{ x }})) %>%
    enframe("column") %>%
    # Workaround: Can't call bind_rows() here with dplyr < 0.9.0
    # Can't call unnest() either for an unknown reason
    mutate(candidate = map_lgl(value, "unique"), data = map(value, list("data", 1))) %>%
    select(-value) %>%
    mutate(values = map_chr(data, ~ commas(format(.$value, trim = TRUE, justify = "none"), capped = TRUE))) %>%
    select(-data) %>%
    mutate(why = if_else(candidate, "", paste0("has duplicate values: ", values))) %>%
    select(-values) %>%
    arrange(desc(candidate), column)
}
