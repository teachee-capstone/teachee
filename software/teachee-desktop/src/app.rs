use std::{
    error::Error,
    fmt,
    fs::{remove_file, File},
    ops::RangeInclusive,
    sync::{Arc, RwLock},
};

use csv::Writer;

use eframe::egui::*;
use std::time::{SystemTime, UNIX_EPOCH};

use crate::controller::{AppData, BufferState, SAMPLE_RATE_PER_CHANNEL};

#[derive(Debug, Default)]
enum TriggerControl {
    #[default]
    Start,
    Stop,
}

// Allows enum to be formatted to string
impl fmt::Display for TriggerControl {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Debug::fmt(self, f)
    }
}

const GROUP_SPACING: f32 = 3.0;
const BUTTON_HEIGHT: f32 = 25.0;
const ERROR_COLOUR: Color32 = Color32::LIGHT_RED;

// 1 MSPS
const SAMPLE_PERIOD: f64 = 1.0 / (SAMPLE_RATE_PER_CHANNEL as f64);

const H_SCALE_RANGE: RangeInclusive<f64> = RangeInclusive::new(0.1, 10.0);
const H_OFFSET_RANGE: RangeInclusive<f64> =
    RangeInclusive::new(-10000.0 * SAMPLE_PERIOD, 10000.0 * SAMPLE_PERIOD);
const V_SCALE_RANGE: RangeInclusive<f64> = RangeInclusive::new(0.1, 10.0);
const V_OFFSET_RANGE: RangeInclusive<f64> = RangeInclusive::new(-5.0, 5.0);

#[derive(Debug)]
struct UIControls {
    h_offset: f64,
    h_scale: f64,
    channel1_v_offset: f64,
    channel1_v_scale: f64,
    channel2_v_offset: f64,
    channel2_v_scale: f64,
    v_trigger_button_text: TriggerControl,
    v_trigger_threshold_text: String,
    v_trigger_format_wrong: bool,
    c_trigger_button_text: TriggerControl,
    c_trigger_threshold_text: String,
    c_trigger_format_wrong: bool,
    export_error_string: String,
    fft: bool,
}

impl Default for UIControls {
    fn default() -> Self {
        Self {
            h_offset: 0.0,
            h_scale: 1.0,
            channel1_v_offset: 0.0,
            channel1_v_scale: 1.0,
            channel2_v_offset: 0.0,
            channel2_v_scale: 1.0,
            v_trigger_button_text: TriggerControl::default(),
            v_trigger_threshold_text: String::new(),
            v_trigger_format_wrong: false,
            c_trigger_button_text: TriggerControl::default(),
            c_trigger_threshold_text: String::new(),
            c_trigger_format_wrong: false,
            export_error_string: String::new(),
            fft: false,
        }
    }
}

#[derive(Debug)]
pub struct App {
    data: AppData,
    buf_idx: usize,
    ui_controls: UIControls,
}

impl App {
    pub fn new(data: AppData) -> Self {
        Self {
            data,
            buf_idx: 0,
            ui_controls: UIControls::default(),
        }
    }
}

fn update_trigger(
    ui: &mut Ui,
    trigger_val: &mut Arc<RwLock<f64>>,
    button_text: &mut TriggerControl,
    textedit_text: &mut String,
    format_wrong: &mut bool,
    (offset, scale): (f64, f64),
    hint_text: &str,
) {
    ui.with_layout(
        Layout::top_down(Align::Center).with_cross_align(Align::Min),
        |ui| {
            if *format_wrong {
                ui.style_mut().visuals.extreme_bg_color = ERROR_COLOUR;
            }
            let re = ui.add(
                TextEdit::singleline(textedit_text)
                    .hint_text(hint_text)
                    .desired_width(f32::INFINITY),
            );
            if re.lost_focus() && re.ctx.input().key_pressed(Key::Enter) {
                let parsed = textedit_text.parse::<f64>();
                match parsed {
                    Ok(new_value) => {
                        *trigger_val.write().unwrap() = new_value;
                        *button_text = TriggerControl::Stop;
                        *format_wrong = false;
                    }
                    Err(_) => {
                        *format_wrong = true;
                    }
                }
            }
        },
    );
    if ui
        .add(Button::new(button_text.to_string()).min_size((0.0, BUTTON_HEIGHT).into()))
        .clicked()
    {
        use TriggerControl::*;
        match button_text {
            Start => {
                let parsed = textedit_text.parse::<f64>();
                match parsed {
                    Ok(new_value) => {
                        *trigger_val.write().unwrap() = (new_value - offset) / scale;
                        *button_text = Stop;
                        *format_wrong = false;
                    }
                    Err(_) => {
                        *format_wrong = true;
                    }
                }
            }
            Stop => {
                *trigger_val.write().unwrap() = f64::INFINITY;
                *button_text = Start;
            }
        };
    }
}

fn offset_scale_sliders(
    ui: &mut Ui,
    offset: &mut f64,
    o_range: RangeInclusive<f64>,
    scale: &mut f64,
    s_range: RangeInclusive<f64>,
) {
    ui.columns(2, |uis| {
        uis[0].label("Offset");
        uis[0].add(Slider::new(offset, o_range).clamp_to_range(false));
        uis[1].label("Scale");
        uis[1].add(
            Slider::new(scale, s_range)
                .clamp_to_range(false)
                .logarithmic(true),
        );
    });
}

impl eframe::App for App {
    fn update(&mut self, ctx: &Context, frame: &mut eframe::Frame) {
        // Always redraw on the next frame. Ensures that state changes from
        // other threads are immediately reflected in the UI.
        ctx.request_repaint();

        let Self {
            data,
            buf_idx,
            ui_controls,
            ..
        } = self;

        TopBottomPanel::top("top").show(ctx, |ui| {
            ui.horizontal_wrapped(|ui| {
                ui.visuals_mut().button_frame = false;
                widgets::global_dark_light_mode_switch(ui);
                ui.separator();
                ui.menu_button("File", |ui| {
                    let mut export_button = Button::new("Export to CSV");
                    if !ui_controls.export_error_string.is_empty() {
                        export_button = export_button.fill(ERROR_COLOUR);
                    }
                    let mut re = ui.add(export_button);
                    if !ui_controls.export_error_string.is_empty() {
                        re = re.on_hover_text(&ui_controls.export_error_string);
                    }

                    if re.clicked() {
                        let epoch_time = SystemTime::now()
                            .duration_since(UNIX_EPOCH)
                            .unwrap()
                            .as_secs();
                        let pid = std::process::id();
                        let file_name = format!("{}-{}-{}", epoch_time, pid, "teachee.csv");
                        let file = match File::create(file_name.clone()) {
                            Ok(a) => a,
                            Err(_) => {
                                ui_controls.export_error_string =
                                    format!("Unable to open file: {}", file_name);
                                return;
                            }
                        };
                        let mut writer = Writer::from_writer(file);
                        let (condvar, mutex) = &*data.bufs[*buf_idx];
                        let mut buf_state = condvar
                            .wait_while(mutex.lock().unwrap(), |buf_state| buf_state.is_empty())
                            .unwrap();
                        let (channels, num_samples) = buf_state.unwrap();

                        let v_strs = channels.voltage1[0..num_samples]
                            .iter()
                            .map(|e| e.to_string());

                        let c_strs = channels.current1[0..num_samples]
                            .iter()
                            .map(|e| e.to_string());
                        let do_writing = move || -> Result<(), Box<dyn Error>> {
                            writer.write_field("Channel1")?;
                            writer.write_record(v_strs)?;
                            writer.write_field("Channel2")?;
                            writer.write_record(c_strs)?;
                            Ok(())
                        };

                        if let Err(e) = do_writing() {
                            ui_controls.export_error_string =
                                format!("Error writing csv output: {e}");
                            _ = remove_file(file_name);
                            return;
                        }

                        ui_controls.export_error_string.clear();
                    }

                    if ui.button("Exit").clicked() {
                        frame.close();
                    }
                });
            })
        });

        SidePanel::right("controls")
            .resizable(false)
            .show(ctx, |ui| {
                ui.vertical_centered(|ui| {
                    ui.add_space(GROUP_SPACING);

                    ui.group(|ui| {
                        ui.add_space(GROUP_SPACING);
                        ui.label(RichText::new("Channel scaling").size(14.0));

                        ui.add(Separator::default().spacing(GROUP_SPACING * 2.0));

                        ui.label("Horizontal");
                        ui.add_space(GROUP_SPACING);
                        offset_scale_sliders(
                            ui,
                            &mut ui_controls.h_offset,
                            H_OFFSET_RANGE,
                            &mut ui_controls.h_scale,
                            H_SCALE_RANGE,
                        );

                        ui.add(Separator::default().spacing(GROUP_SPACING * 2.0));

                        ui.label("Channel 1 Vertical");
                        ui.add_space(GROUP_SPACING);
                        offset_scale_sliders(
                            ui,
                            &mut ui_controls.channel1_v_offset,
                            V_OFFSET_RANGE,
                            &mut ui_controls.channel1_v_scale,
                            V_SCALE_RANGE,
                        );

                        ui.add_space(GROUP_SPACING);

                        ui.label("Channel 2 Vertical");
                        ui.add_space(GROUP_SPACING);
                        offset_scale_sliders(
                            ui,
                            &mut ui_controls.channel2_v_offset,
                            V_OFFSET_RANGE,
                            &mut ui_controls.channel2_v_scale,
                            V_SCALE_RANGE,
                        );
                    });

                    ui.add_space(GROUP_SPACING);

                    ui.group(|ui| {
                        ui.add_space(GROUP_SPACING);
                        ui.label(RichText::new("Triggers").size(14.0));

                        ui.add(Separator::default().spacing(GROUP_SPACING * 2.0));

                        ui.vertical_centered_justified(|ui| {
                            update_trigger(
                                ui,
                                &mut data.voltage_trigger_threshold,
                                &mut ui_controls.v_trigger_button_text,
                                &mut ui_controls.v_trigger_threshold_text,
                                &mut ui_controls.v_trigger_format_wrong,
                                (ui_controls.channel1_v_offset, ui_controls.channel1_v_scale),
                                "Channel 1",
                            );
                            update_trigger(
                                ui,
                                &mut data.current_trigger_threshold,
                                &mut ui_controls.c_trigger_button_text,
                                &mut ui_controls.c_trigger_threshold_text,
                                &mut ui_controls.c_trigger_format_wrong,
                                (ui_controls.channel2_v_offset, ui_controls.channel2_v_scale),
                                "Channel 2",
                            );
                        });
                    });

                    ui.add_space(GROUP_SPACING);

                    ui.group(|ui| {
                        ui.add_space(GROUP_SPACING);
                        ui.label(RichText::new("FFT").size(14.0));

                        ui.add(Separator::default().spacing(GROUP_SPACING * 2.0));

                        ui.vertical_centered_justified(|ui| {
                            if ui.toggle_value(&mut ui_controls.fft, "Channel 1").clicked() {
                                *data.fft.write().unwrap() = ui_controls.fft;
                            }
                        });
                    });

                    ui.add_space(GROUP_SPACING);

                    ui.group(|ui| {
                        ui.add_space(GROUP_SPACING);
                        ui.label(RichText::new("Reset All Configurations").size(14.0));

                        ui.add(Separator::default().spacing(GROUP_SPACING * 2.0));

                        ui.vertical_centered_justified(|ui| {
                            if ui
                                .add(Button::new("Reset").min_size((0.0, BUTTON_HEIGHT).into()))
                                .clicked()
                            {
                                *ui_controls = UIControls::default();
                                *data.voltage_trigger_threshold.write().unwrap() = f64::INFINITY;
                                *data.current_trigger_threshold.write().unwrap() = f64::INFINITY;
                                *data.fft.write().unwrap() = false;
                            }
                        });
                    })
                });
            });

        CentralPanel::default().show(ctx, |ui| {
            // Get the current buffer. Alternating between buffers is done by toggling
            // the buf_idx.
            let (condvar, mutex) = &*data.bufs[*buf_idx];

            // Wait until controller thread has filled the current buffer.
            let mut buf_state = condvar
                .wait_while(mutex.lock().unwrap(), |buf_state| buf_state.is_empty())
                .unwrap();

            let (channels, num_samples) = buf_state.unwrap();

            // Mapping i -> t using the fixed sample rate to get point (i * period, samples[i]).
            let voltage = plot::Line::new(plot::PlotPoints::from_parametric_callback(
                |i| {
                    (
                        i * SAMPLE_PERIOD * ui_controls.h_scale + ui_controls.h_offset,
                        channels.voltage1[i as usize] * ui_controls.channel1_v_scale
                            + ui_controls.channel1_v_offset,
                    )
                },
                0.0..(num_samples as f64),
                num_samples,
            ))
            .name("Channel 1");

            let current = plot::Line::new(plot::PlotPoints::from_parametric_callback(
                |i| {
                    (
                        i * SAMPLE_PERIOD * ui_controls.h_scale + ui_controls.h_offset,
                        channels.current1[i as usize] * ui_controls.channel2_v_scale
                            + ui_controls.channel2_v_offset,
                    )
                },
                0.0..(num_samples as f64),
                num_samples,
            ))
            .name("Channel 2");

            let fft_line = if ui_controls.fft {
                plot::Line::new(plot::PlotPoints::from_parametric_callback(
                    |i| {
                        (
                            channels.fft1.data()[i as usize].0.val() as f64,
                            channels.fft1.data()[i as usize].1.val() as f64,
                        )
                    },
                    0.0..(channels.fft1.data().len() as f64),
                    channels.fft1.data().len(),
                ))
                .name("Channel 1 FFT")
            } else {
                plot::Line::new(plot::PlotPoints::default())
            };

            // Next update, use the other buffer.
            *buf_idx ^= 0x1;
            *buf_state = BufferState::Empty(channels);
            condvar.notify_one();
            drop(buf_state);

            let plot_height = (frame.info().window_info.size.y - 42.0) / 2.0;
            let mut time_plot = plot::Plot::new("plot").legend(plot::Legend::default());
            if ui_controls.fft {
                time_plot = time_plot.height(plot_height);
            }

            time_plot.show(ui, |ui| {
                ui.line(voltage);
                ui.line(current);
            });

            if ui_controls.fft {
                plot::Plot::new("fft")
                    .height(plot_height)
                    .legend(plot::Legend::default())
                    .show(ui, |ui| {
                        ui.line(fft_line);
                    });
            }
        });
    }
}
