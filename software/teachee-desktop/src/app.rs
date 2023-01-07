use std::{f64::consts::TAU, fmt};

use eframe::egui::*;

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
    channel1_on: bool,
    channel2_on: bool,
    trigger_button_text: TriggerControl,
}

#[derive(Debug, Default)]
pub struct App {
    flag: bool,
    channel1: Channel,
    channel1_offset: f64,
    channel2: Channel,
    channel2_offset: f64,
    ui_controls: UIControls,
}

impl App {
    pub fn flip_flag(&mut self) {
        self.flag = !self.flag
    }
}

fn generate_points(
    start: i64,
    stop: i64,
    step: f64,
    channel: &Channel,
    offset: &f64,
) -> Vec<[f64; 2]> {
    if let Channel::Off = channel {
        Vec::new()
    } else {
        let f = match channel {
            Channel::Sine => f64::sin,
            Channel::Cos => f64::cos,
            Channel::Off => unreachable!(),
        };

        (start..stop)
            .map(|i| {
                let x = i as f64 * step;
                [x, f(x + offset)]
            })
            .collect()
    }
}

fn channel_control(ui: &mut Ui, label: &str, channel: &mut Channel, offset: &mut f64) {
    CollapsingHeader::new(label)
        .default_open(true)
        .show(ui, |ui| {
            ComboBox::from_label("Input")
                .selected_text(format!("{:?}", channel))
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
                            if ui
                                .add(
                                    Button::new(ui_controls.trigger_button_text.to_string())
                                        .min_size((0.0, BUTTON_HEIGHT).into()),
                                )
                                .clicked()
                            {
                                use TriggerControl::*;
                                // TODO: enable/disable triggering
                                ui_controls.trigger_button_text =
                                    match ui_controls.trigger_button_text {
                                        Start => Stop,
                                        Stop => Start,
                                    };
                            }
                        });
                    });
                });
            });

        CentralPanel::default().show(ctx, |ui| {
            ScrollArea::vertical().show(ui, |ui| {
                let lines = [
                    generate_points(0, 1000, 0.01, channel1, channel1_offset),
                    generate_points(0, 1000, 0.01, channel2, channel2_offset),
                ]
                .into_iter()
                .map(plot::Line::new);

                plot::Plot::new("plot")
                    .data_aspect(1.0)
                    .allow_drag(false)
                    .allow_scroll(false)
                    .allow_zoom(false)
                    .allow_boxed_zoom(false)
                    .show(ui, |ui| lines.for_each(|l| ui.line(l)));
            });
        });
    }
}
