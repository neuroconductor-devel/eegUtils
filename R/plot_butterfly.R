#' Create a butterfly plot from timecourse data
#'
#' Typically event-related potentials/fields, but could also be timecourses from
#' frequency analyses for single frequencies. Output is a ggplot2 object. CIs
#' not possible.
#'
#' @section Notes on ggplot2 facetting:
#'
#'   In order for ggplot2 facetting to work, the data has to be plotted using
#'   `stat_summary()` rather than `geom_line()`, so that the plots can still be
#'   made when not all categorical variables are reflected in the facets. e.g.
#'   if there are two variables with two levels each, but you want to average
#'   over one of those variables, `stat_summary()` is required. However,
#'   `stat_summary()` is extremely slow.
#'
#' @author Matt Craddock, \email{matt@@mattcraddock.com}
#' @param data EEG dataset. Should have multiple timepoints.
#' @param ... Other parameters passed to plot_butterfly
#' @examples
#' plot_butterfly(demo_epochs)
#' plot_butterfly(demo_epochs,
#' time_lim = c(-.1, .4),
#' legend = FALSE)
#' @return A ggplot object
#' @export

plot_butterfly <- function(data, ...) {
  UseMethod("plot_butterfly", data)
}

#' @param time_lim Character vector. Numbers in whatever time unit is used
#'   specifying beginning and end of time-range to plot. e.g. c(-.1,.3)
#' @param baseline  Character vector. Times to use as a baseline. Takes the mean
#'   over the specified period and subtracts. e.g. c(-.1, 0)
#' @param colourmap Attempt to plot using a different colourmap (from
#'   RColorBrewer). (Not yet implemented)
#' @param legend Include plot legend. Defaults to TRUE.
#' @param allow_facets Allow use of ggplot2 facetting. See note below. Defaults
#'   to FALSE.
#' @param continuous Is the data continuous or not (I.e. epoched)
#' @param browse_mode Custom theme for use with browse_data.
#' @return ggplot2 object showing ERPs for all electrodes overlaid on a single
#'   plot.
#' @import ggplot2
#' @importFrom dplyr group_by ungroup summarise
#' @importFrom tidyr gather
#' @describeIn plot_butterfly Default `plot_butterfly` method for data.frames,
#'   `eeg_data`
#' @export

plot_butterfly.default <- function(data,
                                   time_lim = NULL,
                                   baseline = NULL,
                                   colourmap = NULL,
                                   legend = TRUE,
                                   continuous = FALSE,
                                   browse_mode = FALSE,
                                   allow_facets = FALSE,
                                   ...) {

  if (browse_mode == FALSE) {
    data <- dplyr::group_by(data,
                            time,
                            electrode)
    data <- dplyr::summarise(data,
                             amplitude = mean(amplitude))
    data <- dplyr::ungroup(data)
  }

  ## select time-range of interest -------------

  if (!is.null(time_lim)) {
    data <- select_times(data,
                         time_lim)
  }

  if (!is.null(baseline)) {
    data <- rm_baseline(data,
                        baseline)
  }

  #Set up basic plot -----------
  create_bf(data,
            legend = legend,
            browse_mode = browse_mode,
            continuous = FALSE,
            allow_facets = allow_facets)
}

#' @describeIn plot_butterfly Plot butterfly for `eeg_evoked` objects
#' @export
plot_butterfly.eeg_evoked <- function(data,
                                      time_lim = NULL,
                                      baseline = NULL,
                                      colourmap = NULL,
                                      legend = TRUE,
                                      continuous = FALSE,
                                      browse_mode = FALSE,
                                      allow_facets = FALSE,
                                      ...) {

  data <- parse_for_bf(data,
                       time_lim,
                       baseline)

  create_bf(data,
            legend = legend,
            browse_mode = browse_mode,
            continuous = FALSE,
            allow_facets = allow_facets)
}

#' @describeIn plot_butterfly Create butterfly plot for `eeg_data` objects
#' @export
plot_butterfly.eeg_data <- function(data,
                                    time_lim = NULL,
                                    baseline = NULL,
                                    legend = TRUE,
                                    allow_facets = FALSE,
                                    browse_mode = FALSE,
                                    ...) {

  data <- parse_for_bf(data,
                       time_lim,
                       baseline)
  create_bf(data,
            legend = legend,
            browse_mode = browse_mode,
            continuous = TRUE,
            allow_facets = allow_facets)
}

#' @describeIn plot_butterfly Create butterfly plot for `eeg_epochs` objects
#' @export
plot_butterfly.eeg_epochs <- function(data,
                                      time_lim = NULL,
                                      baseline = NULL,
                                      legend = TRUE,
                                      allow_facets = FALSE,
                                      browse_mode = FALSE,
                                      ...) {


  data <- eeg_average(data)
  data <- parse_for_bf(data,
                       time_lim,
                       baseline)
  create_bf(data,
            legend = legend,
            browse_mode = browse_mode,
            continuous = FALSE,
            allow_facets = allow_facets)
}

#' @describeIn plot_butterfly Create butterfly plot for `eeg_stats` objects
#' @export
plot_butterfly.eeg_stats <- function(data,
                                     time_lim = NULL,
                                     baseline = NULL,
                                     legend = TRUE,
                                     allow_facets = FALSE,
                                     browse_mode = FALSE,
                                     quantity = "statistic",
                                     ...) {

  data <- parse_for_bf(data,
                       time_lim,
                       baseline = NULL)
  create_bf(data,
            legend = legend,
            browse_mode = browse_mode,
            continuous = FALSE,
            quantity = {{quantity}},
            allow_facets = allow_facets)
}


#' @describeIn plot_butterfly Create butterfly plot for `eeg_lm` objects
#' @param quantity Which aspect of the linear model you want to be plotted. only
#'   applies to `eeg_lm` objects
#' @export
plot_butterfly.eeg_lm <- function(data,
                                  time_lim = NULL,
                                  baseline = NULL,
                                  legend = TRUE,
                                  allow_facets = FALSE,
                                  browse_mode = FALSE,
                                  quantity = "coefficients",
                                  ...) {


  data <- parse_for_bf(data,
                       time_lim,
                       baseline = NULL,
                       quantity = quantity)

  if (identical(quantity, "coefficients")) {
    quantity <- "amplitude"
    ylab <- expression(paste("Amplitude (", mu, "V)"))
  } else if (identical(quantity, "t_stats")) {
    quantity <- "statistic"
    ylab <- expression(italic("t")~"-statistic")
  } else if (identical(quantity, "std_err")) {
    ylab <- expression(paste("Std. error (", mu, "V)"))
  } else if (identical(quantity, "r_sq")) {
    ylab <- expression(paste(italic("r"), {}^2))
  }

   if (is.character(quantity)) {
     quantity <- as.name(quantity)
   }

  create_bf(data,
            legend = legend,
            browse_mode = browse_mode,
            continuous = FALSE,
            quantity = {{quantity}},
            allow_facets = allow_facets,
            ylab = ylab)
}

#' Parse data for butterfly plots
#'
#' Internal command for parsing various data structures into a suitable format
#' for `plot_butterfly`
#'
#' @param data data to be parsed
#' @param time_lim time limits to be returned.
#' @param baseline baseline times to be average and subtracted
#' @keywords internal
parse_for_bf <- function(data,
                         time_lim = NULL,
                         baseline = NULL,
                         quantity = "coefficients") {

  # Select specifed times
  if (!is.null(time_lim)) {
    data <- select_times(data,
                         time_lim = time_lim)
  }

  ## Do baseline correction
  if (!is.null(baseline)) {
    data <- rm_baseline(data,
                        time_lim = baseline)
  }
  data <- as.data.frame(data,
                        long = TRUE,
                        coords = FALSE,
                        values = {{quantity}})
  data
}

#' @import ggplot2
#' @keywords internal
create_bf <- function(data,
                      legend,
                      browse_mode,
                      continuous,
                      quantity = amplitude,
                      allow_facets,
                      ylab = expression(paste("Amplitude (", mu, "V)"))) {

  if (browse_mode) {
    allow_facets <- TRUE
  }

  if (!allow_facets) {
    data <- dplyr::group_by(data,
                            time,
                            electrode)
    data <- dplyr::summarise_at(data,
                                vars({{quantity}}),
                                mean)
    # data <- dplyr::summarise(data,
    #                          !!quo_name(quantity) := mean({{quantity}}))
    data$epoch <- 1
  }

  #Set up basic plot -----------
  butterfly_plot <-
    ggplot2::ggplot(data,
                    aes(x = time,
                        y = {{quantity}}))

  if (length(unique(data$epoch)) > 1) {
    chan_lines <- function() {
      stat_summary(fun = mean,
                   geom = "line",
                   aes(colour = electrode),
                   alpha = 0.5)
    }
  } else {
    chan_lines <- function() {
      geom_line(aes(colour = electrode),
                alpha = 0.5)
    }
  }


  if (browse_mode) {
    butterfly_plot <-
      butterfly_plot +
      geom_line(colour = "black",
                aes(group = electrode),
                alpha = 0.2) +
      labs(x = "Time (s)",
           y = ylab,
           colour = "") +
      geom_hline(yintercept = 0,
                 size = 0.5,
                 linetype = "dashed",
                 alpha = 0.5) +
      scale_x_continuous(expand = c(0, 0)) +
      theme_minimal(base_size = 12) +
      theme(panel.grid = element_blank(),
            axis.ticks = element_line(size = .5))
  } else {
    butterfly_plot <-
      butterfly_plot +
      chan_lines() +
      labs(x = "Time (s)",
           y = ylab,#expression(paste("Amplitude (", mu, "V)")),
           colour = "") +
      geom_hline(yintercept = 0, size = 0.5) +
      scale_x_continuous(expand = c(0, 0)) +
      theme_minimal(base_size = 12) +
      theme(panel.grid = element_blank(),
            axis.ticks = element_line(size = .5))

    if (!continuous) {
      butterfly_plot <-
        butterfly_plot +
        geom_vline(xintercept = 0, size = 0.5)
    }
  }

  if (legend) {
    butterfly_plot +
      guides(colour = guide_legend(override.aes = list(alpha = 1)))
  } else {
    butterfly_plot +
      theme(legend.position = "none")
  }
}
