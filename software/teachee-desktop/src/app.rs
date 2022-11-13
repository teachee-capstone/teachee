use std::f64::consts::TAU;

use eframe::egui::*;

#[derive(Debug, Clone, Copy, Default, PartialEq)]
enum Channel {
    #[default]
    Off,
    Sine,
    Cos,
}

#[derive(Debug, Default)]
pub struct App {
    flag: bool,
    channel1: Channel,
    channel1_offset: f64,
    channel2: Channel,
    channel2_offset: f64,
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
    fn update(&mut self, ctx: &Context, _frame: &mut eframe::Frame) {
        // Always redraw on the next frame. Ensures that state changes from
        // other threads are immediately reflected in the UI.
        ctx.request_repaint();

        let Self {
            flag,
            channel1,
            channel1_offset,
            channel2,
            channel2_offset,
            ..
        } = self;

        SidePanel::right("controls")
            .resizable(false)
            .show(ctx, |ui| {
                ScrollArea::vertical()
                    .auto_shrink([false, false])
                    .show(ui, |ui| {
                        channel_control(ui, "Channel 1", channel1, channel1_offset);
                        channel_control(ui, "Channel 2", channel2, channel2_offset);
                    });
            });

        TopBottomPanel::top("top").show(ctx, |ui| {
            ui.horizontal_wrapped(|ui| {
                ui.visuals_mut().button_frame = false;
                widgets::global_dark_light_mode_switch(ui);
                ui.separator();
                ui.label(if *flag { "Flag: 1" } else { "Flag: 0" });
            })
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
