
library(readxl)
library(readr)
library(optparse)
library(dplyr)

parse_filepath <- function(opt) {
  if (is.null(opt$f)) {
    cat("Filepath is not specified, looking for in workdir, by default './excel_import_data'\n")
    potential_filenames <- list.files(opt$dir, pattern = ".xlsx")
    cat("Choose filename number\n")
    cat(
            paste0(
                "\t",
                seq_along(potential_filenames),
                " ",
                potential_filenames, "\n"
            )
        )

    filenum <- parse_number(readLines(file("stdin"), 1))
    filepath <- file.path(opt$dir, potential_filenames[filenum])
    cat(paste0("Choosed relative file path: \"", filepath, "\"\n"))
  } else {

    filepath <- opt$f
    cat(paste0("Specified filepath: ", filepath, "\n"))
  }
  return(filepath)
}

# Why we parse all common info and don't use it later?
# I don't know. But it can be useful...
parse_common_info <- function(filepath) {
  read_excel(filepath,
        sheet = 1,
        range = "A7:I69",
        col_names = c(
            "name",
            "city",
            "post",
            "department",
            "email",
            "sex",
            "status",
            "eval_date",
            "project_name"
        ),
        col_types = c(
            "text",
            "text",
            "text",
            "text",
            "text",
            "text",
            "text",
            "date",
            "text"
        )
    )
}


# Parse answers from excel and pivot (transpose) them
parse_answers <- function(filepath) {
  user_answers <- read_excel(filepath,
        sheet = 1,
        range = "K6:AGL69",
        col_types = "numeric"
    )
  correct_answers <- read_excel(filepath,
        sheet = 1,
        range = "K5:AGL5",
        col_types = "numeric",
        col_names = colnames(user_answers)
    )

  section_names <-read_excel(filepath,
        sheet = 1,
        range = "K2:AGL2",
        col_types = "text",
        col_names = colnames(user_answers)
    ) %>% pivot_longer(
      everything(),
      names_to = "question",
      values_to = "section"
    ) %>% 
    fill(section, .direction = 'down')
  

  answers <- bind_rows(correct_answers, user_answers)


  common_info <- parse_common_info(filepath) %>%
        add_row(.before = 1)


  answers <- bind_cols(common_info, answers)


  pivot_answers <- answers %>%
        select(name, contains(".")) %>%
        pivot_longer(
            contains("."),
            names_to = "question",
            values_to = "answer",
            names_repair = "unique"
        )


  pivot_answers <- suppressMessages(pivot_answers %>% left_join(
        section_names
    ))

  correct_answers <- pivot_answers %>%
        filter(is.na(name)) %>%
        select(question, answer)

  final_pivot <- pivot_answers %>%
        filter(!is.na(name)) %>%
        left_join(correct_answers, by = "question") %>%
        ungroup()

  return(final_pivot)
}

analyze_answers <- function(answers) {
  answers <- answers %>%
    mutate(good_answer = bitwAnd(answer.x, answer.y)) %>%
    group_by(
        section, name
    ) %>%
    summarise(good_ans_sum = sum(good_answer, na.rm = T)) %>%
    ungroup() %>%
    group_by(section) %>%
    mutate(
        z = round(
            (good_ans_sum - mean(good_ans_sum)) / sd(good_ans_sum), 2
        ),
        z_cut = pmin(pmax(z, -3), 3)
    ) %>%
    ungroup()

  # Calc cut z-value mean
  answers <- answers %>%
    group_by(name) %>%
    mutate(z_cut_mean = round(mean(z_cut), 2)) %>%
    ungroup()

  # Calc percentile by ECOPSY special formula
  answers <- answers %>%
    group_by(section) %>%
    mutate(temp_z_cut = z_cut) %>%
    mutate(
        z_cut_lt = sapply(z_cut, count_lt_v, temp_z_cut),
        z_cut_equal = sapply(z_cut, count_equal_v, temp_z_cut),
        z_total = n()
    ) %>%
    mutate(z_val = ceiling((z_cut_lt + z_cut_equal / 2) / z_total * 100)) %>%
    ungroup() %>%
    select(-temp_z_cut)

  # Calc percentile for common value by ECOPSY special formula
  answers <- answers %>%
    mutate(temp_z_cut_mean = z_cut_mean) %>%
    mutate(
        z_cut_lt_mean = sapply(z_cut_mean, count_lt_v, temp_z_cut_mean),
        z_cut_equal_mean = sapply(z_cut_mean, count_equal_v, temp_z_cut_mean),
        z_total_mean = n()
    ) %>%
    mutate(z_val_mean = ceiling(
        (z_cut_lt_mean + z_cut_equal_mean / 2) / z_total_mean * 100
    )) %>%
    ungroup()
}


count_lt_v <- function(x, vec_num) {
  return(sum(vec_num < x))
}

count_equal_v <- function(x, vec_num) {
  return(sum(vec_num == x))
}

adapt_df_to_JSON <- function(answers) {
  answers_for_json <- answers %>%
    select(name, section, good_ans_sum, z, z_cut, z_cut_mean, z_val, z_val_mean) %>%
    pivot_wider(
        names_from = section, values_from = c(good_ans_sum, z, z_cut, z_val)
    ) %>%
    ungroup()


  colnames(answers_for_json) <- c(
    "FIO",
    "z_cut_mean",
    "z_total_common",
    "raw_communication_competence",
    "raw_search_storage_transfer_digital_content",
    "raw_creation_digital_content",
    "raw_information_security",
    "z_communication_competence",
    "z_search_storage_transfer_digital_content",
    "z_creation_digital_content",
    "z_information_security",
    "z_cut_communication_competence",
    "z_cut_search_storage_transfer_digital_content",
    "z_cut_creation_digital_content",
    "z_cut_information_security",
    "z_total_communication_competence",
    "z_total_search_storage_transfer_digital_content",
    "z_total_creation_digital_content",
    "z_total_information_security"
  )

  return(answers_for_json)
}

create_nested_df <- function(answers_for_json) {
  nested_df <- as.data.frame(answers_for_json %>%
    select(FIO, z_total_common, z_cut_mean))

  nested_df$raw <- as.data.frame(
    answers_for_json %>%
    select(
    raw_communication_competence,
    raw_search_storage_transfer_digital_content,
    raw_creation_digital_content,
    raw_information_security)
  )

  nested_df$zscore <- as.data.frame(
    answers_for_json %>%
    select(
    z_cut_communication_competence,
    z_cut_search_storage_transfer_digital_content,
    z_cut_creation_digital_content,
    z_cut_information_security)
  )

  nested_df$percentiles <- as.data.frame(
    answers_for_json %>%
    select(
    z_total_communication_competence,
    z_total_search_storage_transfer_digital_content,
    z_total_creation_digital_content,
    z_total_information_security)
  )

  for (i in c("raw", "zscore", "percentiles")) {
    colnames(nested_df[[i]]) <- c(
        'communication_competence',
        'search_storage_transfer_digital_content',
        'creation_digital_content',
        'information_security'
    )
  }

  return(nested_df)
}
