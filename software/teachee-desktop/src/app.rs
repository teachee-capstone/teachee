use std::{f64::consts::TAU, fmt};

use eframe::egui::*;

use crate::controller::{AppData, BufferState};

#[derive(Debug, Clone, Copy, Default, PartialEq)]
enum Channel {
    #[default]
    Off,
    Sine,
    Cos,
}

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
const TEXTEDIT_WIDTH: f32 = 30.0;

#[derive(Debug, Default)]
struct UIControls {
    h_offset: f64,
    h_scale: f64,
    v_offset: f64,
    v_scale: f64,
    // TODO: use unused fields
    _saved_v_offset: f64,
    _saved_v_scale: f64,
    _channel1_v_offset: f64,
    _channel1_v_scale: f64,
    _channel2_v_offset: f64,
    _channel2_v_scale: f64,
    h_scale_str: String,
    channel1_v_scale_str: String,
    channel2_v_scale_str: String,
    channel1_on: bool,
    channel2_on: bool,
    trigger_button_text: TriggerControl,
    trigger_threshold_text: String,
    trigger_format_wrong: bool,
}

#[derive(Debug)]
pub struct App {
    flag: bool,
    channel1: Channel,
    channel1_offset: f64,
    channel2: Channel,
    channel2_offset: f64,
    data: AppData,
    buf_idx: usize,
    ui_controls: UIControls,
}

impl App {
    pub fn new(data: AppData) -> Self {
        Self {
            flag: false,
            channel1: Channel::default(),
            channel1_offset: 0.0,
            channel2: Channel::default(),
            channel2_offset: 0.0,
            data,
            buf_idx: 0,
            ui_controls: UIControls::default(),
        }
    }
    pub fn flip_flag(&mut self) {
        self.flag = !self.flag
    }
}

fn channel_control(ui: &mut Ui, label: &str, channel: &mut Channel, offset: &mut f64) {
    CollapsingHeader::new(label)
        .default_open(true)
        .show(ui, |ui| {
            ComboBox::from_label("Input")
                .selected_text(format!("{channel:?}"))
                .show_ui(ui, |ui| {
                    ui.selectable_value(channel, Channel::Off, "Off");
                    ui.selectable_value(channel, Channel::Sine, "Sin");
                    ui.selectable_value(channel, Channel::Cos, "Cos");
                });

            ui.add(
                Slider::new(offset, 0.0..=TAU)
                    .show_value(false)
                    .text("Offset"),
            );
        });
}

impl eframe::App for App {
    fn update(&mut self, ctx: &Context, frame: &mut eframe::Frame) {
        // Always redraw on the next frame. Ensures that state changes from
        // other threads are immediately reflected in the UI.
        ctx.request_repaint();

        let Self {
            flag,
            channel1,
            channel1_offset,
            channel2,
            channel2_offset,
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
                    if ui.button("Export to CSV").clicked() {
                        todo!("Exporting to CSV");
                    }
                    if ui.button("Exit").clicked() {
                        frame.close();
                    }
                });
                ui.separator();
                ui.label(format!("Flag: {}", *flag as i32));
            })
        });

        SidePanel::right("controls")
            .resizable(false)
            .show(ctx, |ui| {
                ui.vertical_centered(|ui| {
                    ui.add_space(GROUP_SPACING);

                    ui.group(|ui| {
                        ui.label("Channel scaling");

                        ui.add_space(GROUP_SPACING);
                        ui.separator();
                        ui.add_space(GROUP_SPACING);

                        ui.label("Horizontal");
                        ui.columns(2, |uis| {
                            uis[0].label("Offset");
                            uis[0].add(
                                Slider::new(&mut ui_controls.h_offset, 0.0..=100.0)
                                    .show_value(false),
                            );
                            uis[1].label("Scale");
                            uis[1].add(
                                Slider::new(&mut ui_controls.h_scale, 0.0..=100.0)
                                    .show_value(false),
                            );
                        });

                        ui.add_space(GROUP_SPACING);
                        ui.separator();
                        ui.add_space(GROUP_SPACING);

                        ui.label("Vertical");
                        ui.group(|ui| {
                            ui.vertical_centered_justified(|ui| {
                                // TODO: save vertical offset/scale when checked and
                                // update individual channel's vertical offset/scale
                                // when unchecked
                                ui.checkbox(&mut ui_controls.channel1_on, "Channel 1");
                            });
                        });
                        ui.group(|ui| {
                            ui.vertical_centered_justified(|ui| {
                                ui.checkbox(&mut ui_controls.channel2_on, "Channel 2");
                            });
                        });
                        ui.columns(2, |uis| {
                            uis[0].label("Offset");
                            uis[0].add(
                                Slider::new(&mut ui_controls.v_offset, 0.0..=100.0)
                                    .show_value(false),
                            );
                            uis[1].label("Scale");
                            uis[1].add(
                                Slider::new(&mut ui_controls.v_scale, 0.0..=100.0)
                                    .show_value(false),
                            );
                        });

                        ui.add_space(GROUP_SPACING);
                        ui.separator();
                        ui.add_space(GROUP_SPACING);

                        ui.vertical_centered_justified(|ui| {
                            if ui
                                .add(Button::new("Reset").min_size((0.0, BUTTON_HEIGHT).into()))
                                .clicked()
                            {
                                *ui_controls = UIControls::default();
                            }
                        });

                        ui.add_space(GROUP_SPACING);
                        // TODO: replace with new controls
                        channel_control(ui, "Channel 1", channel1, channel1_offset);
                        channel_control(ui, "Channel 2", channel2, channel2_offset);
                    });

                    ui.add_space(GROUP_SPACING);

                    ui.group(|ui| {
                        ui.label("Triggers");
                        ui.add_space(GROUP_SPACING);
                        ui.separator();
                        ui.add_space(GROUP_SPACING);
                        ui.vertical_centered_justified(|ui| {
                            ui.with_layout(
                                Layout::top_down(Align::Center).with_cross_align(Align::Min),
                                |ui| {
                                    if ui_controls.trigger_format_wrong {
                                        ui.style_mut().visuals.extreme_bg_color =
                                            Color32::LIGHT_RED;
                                    }
                                    ui.add(
                                        TextEdit::singleline(
                                            &mut ui_controls.trigger_threshold_text,
                                        )
                                        .hint_text("Trigger threshold"),
                                    );
                                },
                            );
                            if ui
                                .add(
                                    Button::new(ui_controls.trigger_button_text.to_string())
                                        .min_size((0.0, BUTTON_HEIGHT).into()),
                                )
                                .clicked()
                            {
                                use TriggerControl::*;
                                match ui_controls.trigger_button_text {
                                    Start => {
                                        let parsed =
                                            ui_controls.trigger_threshold_text.parse::<f64>();
                                        match parsed {
                                            Ok(new_value) => {
                                                *data.trigger_value.write().unwrap() = new_value;
                                                ui_controls.trigger_button_text = Stop;
                                                ui_controls.trigger_format_wrong = false;
                                            }
                                            Err(_) => {
                                                ui_controls.trigger_format_wrong = true;
                                            }
                                        }
                                    }
                                    Stop => {
                                        *data.trigger_value.write().unwrap() = 0.0;
                                        ui_controls.trigger_button_text = Start;
                                    }
                                };
                            }
                        });
                    });
                });
            });

        TopBottomPanel::bottom("labels")
            .resizable(false)
            .show(ctx, |ui| {
                ui.horizontal(|ui| {
                    ui.vertical(|ui| {
                        ui.horizontal(|ui| {
                            ui.label("Channel 1:");
                            if ui
                                .add(
                                    TextEdit::singleline(&mut ui_controls.channel1_v_scale_str)
                                        .desired_width(TEXTEDIT_WIDTH),
                                )
                                .lost_focus()
                            {
                                // TODO: sync string with slider value
                            }
                            ui.label("V/div");
                        });
                        ui.horizontal(|ui| {
                            ui.label("Channel 2:");
                            if ui
                                .add(
                                    TextEdit::singleline(&mut ui_controls.channel2_v_scale_str)
                                        .desired_width(TEXTEDIT_WIDTH),
                                )
                                .lost_focus()
                            {
                                // TODO: sync string with slider value
                            }
                            ui.label("V/div");
                        });
                    });

                    ui.separator();

                    ui.with_layout(Layout::left_to_right(Align::Center), |ui| {
                        if ui
                            .add(
                                TextEdit::singleline(&mut ui_controls.h_scale_str)
                                    .desired_width(TEXTEDIT_WIDTH),
                            )
                            .lost_focus()
                        {
                            // TODO: sync string with slider value
                        }
                        ui.label("ms/div");
                    });
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
            // TODO: get the actual sample period
            // TODO: Scale and offset
            let voltage = plot::Line::new(plot::PlotPoints::from_parametric_callback(
                |i| (i * 0.01, channels.voltage1[i as usize]),
                0.0..(num_samples as f64),
                num_samples,
            ))
            .name("Channel 1");
            let current = plot::Line::new(plot::PlotPoints::from_parametric_callback(
                |i| (i * 0.01, channels.current1[i as usize]),
                0.0..(num_samples as f64),
                num_samples,
            ))
            .name("Channel 2");

            // Next update, use the other buffer.
            *buf_idx ^= 0x1;
            *buf_state = BufferState::Empty(channels);
            condvar.notify_one();

            plot::Plot::new("plot")
                .data_aspect(1.0)
                .allow_drag(false)
                .allow_scroll(false)
                .allow_zoom(false)
                .allow_boxed_zoom(false)
                .legend(plot::Legend::default())
                .show(ui, |ui| {
                    ui.line(voltage);
                    ui.line(current);
                });
        });
    }
}
