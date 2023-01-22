use eframe::egui::{
    plot::{Line, PlotPoints},
    *,
};

use std::{
    collections::VecDeque,
    ops::{Index, IndexMut},
};

const GROUP_SPACING: f32 = 3.0;
const TEXTEDIT_WIDTH: f32 = 30.0;

const CHANNEL_INDICIES: [Channel; 1] = [
    Channel::VoltageA,
    // Channel::VoltageB,
    // Channel::VoltageC,
    // Channel::Current,
];

pub enum Channel {
    VoltageA,
    VoltageB,
    VoltageC,
    Current,
}

#[derive(Debug, Clone)]
struct ChannelState {
    label: &'static str,
    _unit: &'static str,
    capacity: usize,

    sample_buf: VecDeque<f64>,
    sample_period: f64,

    is_on: bool,
    h_offset: f64,
    v_offset: f64,
    h_scale: f64,
    v_scale: f64,
}

impl ChannelState {
    fn new(label: &'static str, unit: &'static str, capacity: usize, sample_rate: f64) -> Self {
        Self {
            label,
            _unit: unit,
            capacity,

            sample_buf: VecDeque::with_capacity(capacity),
            sample_period: 1.0 / sample_rate,

            is_on: false,
            h_offset: 0.0,
            v_offset: 0.0,
            h_scale: 1.0,
            v_scale: 1.0,
        }
    }

    fn store_samples(&mut self, samples: &[f64]) {
        // frontmost sample is the most recent
        for &sample in samples {
            self.sample_buf.push_back(sample);
        }

        while (self.sample_buf.len()) > self.capacity {
            self.sample_buf.pop_front();
        }
    }

    /// https://en.wikipedia.org/wiki/Whittaker%E2%80%93Shannon_interpolation_formula
    fn interpolate(&self, t: f64) -> f64 {
        fn sinc(x: f64) -> f64 {
            x.sin() / x
        }

        let t = t * self.h_scale + self.h_offset;

        let mut sum = 0.0;
        for (n, x) in self.sample_buf.iter().enumerate() {
            let n = n as f64;
            sum += x + sinc(t - n * self.sample_period) / self.sample_period;
        }

        sum * self.v_scale + self.v_offset
    }
}

#[derive(Debug)]
struct ChannelStateArray {
    voltage_a: ChannelState,
    voltage_b: ChannelState,
    voltage_c: ChannelState,
    current: ChannelState,
}

impl Default for ChannelStateArray {
    fn default() -> Self {
        const CAPACITY: usize = 1000;

        Self {
            voltage_a: ChannelState::new("Voltage A", "V", CAPACITY, 1_000.0),
            voltage_b: ChannelState::new("Voltage B", "V", CAPACITY, 1_000_000.0),
            voltage_c: ChannelState::new("Voltage C", "V", CAPACITY, 1_000_000.0),
            current: ChannelState::new("Current", "A", CAPACITY, 1_000_000.0),
        }
    }
}

impl Index<Channel> for ChannelStateArray {
    type Output = ChannelState;

    fn index(&self, index: Channel) -> &Self::Output {
        match index {
            Channel::VoltageA => &self.voltage_a,
            Channel::VoltageB => &self.voltage_b,
            Channel::VoltageC => &self.voltage_c,
            Channel::Current => &self.current,
        }
    }
}

impl IndexMut<Channel> for ChannelStateArray {
    fn index_mut(&mut self, index: Channel) -> &mut Self::Output {
        match index {
            Channel::VoltageA => &mut self.voltage_a,
            Channel::VoltageB => &mut self.voltage_b,
            Channel::VoltageC => &mut self.voltage_c,
            Channel::Current => &mut self.current,
        }
    }
}

#[derive(Debug, Default)]
struct ScopeControls {
    channel_state_array: ChannelStateArray,
    h_scale_str: String,
    channel1_v_scale_str: String,
    channel2_v_scale_str: String,
}

#[derive(Debug, Default)]
pub struct App {
    is_connected: bool,
    scope_controls: ScopeControls,
}

impl App {
    pub fn set_is_connected(&mut self, is_connected: bool) {
        self.is_connected = is_connected;
    }

    pub fn store_samples(&mut self, channel: Channel, samples: &[f64]) {
        self.scope_controls.channel_state_array[channel].store_samples(samples)
    }
}

impl eframe::App for App {
    fn update(&mut self, ctx: &Context, frame: &mut eframe::Frame) {
        // Always redraw on the next frame. Ensures that state changes from
        // other threads are immediately reflected in the UI.
        ctx.request_repaint();

        let Self {
            is_connected,
            scope_controls,
        } = self;

        TopBottomPanel::top("top").show(ctx, |ui| draw_menu_bar(ui, frame, is_connected));

        SidePanel::right("controls")
            .resizable(false)
            .show(ctx, |ui| draw_scope_controls(ui, scope_controls));

        TopBottomPanel::bottom("labels")
            .resizable(false)
            .show(ctx, |ui| draw_plot_labels(ui, scope_controls));

        CentralPanel::default().show(ctx, |ui| {
            draw_plot(ui, &mut scope_controls.channel_state_array)
        });
    }
}

fn draw_menu_bar(ui: &mut Ui, frame: &mut eframe::Frame, _is_connected: &bool) {
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
    });
}

fn draw_scope_controls(ui: &mut Ui, scope_controls: &mut ScopeControls) {
    let ScopeControls {
        channel_state_array,
        ..
    } = scope_controls;

    ScrollArea::vertical().show(ui, |ui| {
        for channel in CHANNEL_INDICIES {
            ui.add_space(GROUP_SPACING);
            ui.group(|ui| draw_channel_controls(ui, &mut channel_state_array[channel]));
        }
    });
}

fn draw_channel_controls(ui: &mut Ui, state: &mut ChannelState) {
    let ChannelState {
        label,
        is_on,
        h_offset,
        v_offset,
        h_scale,
        v_scale,
        ..
    } = state;

    ui.label(*label);
    ui.separator();

    ComboBox::new(format!("{}_state_combo_box", label), "State")
        .selected_text(if *is_on { "On" } else { "Off" })
        .show_ui(ui, |ui| {
            ui.selectable_value(is_on, true, "On");
            ui.selectable_value(is_on, false, "Off");
        });

    ui.add_space(GROUP_SPACING);

    ui.group(|ui| {
        ui.label("Horizontal");
        ui.separator();
        ui.columns(2, |uis| {
            uis[0].label("Offset");
            uis[0].add(Slider::new(h_offset, 0.0..=100.0).show_value(false));
            uis[1].label("Scale");
            uis[1].add(Slider::new(h_scale, 0.0..=100.0).show_value(false));
        });
    });

    ui.add_space(GROUP_SPACING);

    ui.group(|ui| {
        ui.label("Vertical");
        ui.separator();
        ui.columns(2, |uis| {
            uis[0].label("Offset");
            uis[0].add(Slider::new(v_offset, 0.0..=100.0).show_value(false));
            uis[1].label("Scale");
            uis[1].add(Slider::new(v_scale, 0.0..=100.0).show_value(false));
        })
    });
}

fn draw_plot_labels(ui: &mut Ui, scope_controls: &mut ScopeControls) {
    ui.horizontal(|ui| {
        ui.vertical(|ui| {
            ui.horizontal(|ui| {
                ui.label("Channel 1:");
                if ui
                    .add(
                        TextEdit::singleline(&mut scope_controls.channel1_v_scale_str)
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
                        TextEdit::singleline(&mut scope_controls.channel2_v_scale_str)
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
                    TextEdit::singleline(&mut scope_controls.h_scale_str)
                        .desired_width(TEXTEDIT_WIDTH),
                )
                .lost_focus()
            {
                // TODO: sync string with slider value
            }
            ui.label("ms/div");
        });
    });
}

fn draw_plot(ui: &mut Ui, channels: &mut ChannelStateArray) {
    plot::Plot::new("plot").show(ui, |ui| {
        for channel_idx in CHANNEL_INDICIES {
            let channel = &channels[channel_idx];
            if channel.is_on {
                let channel = channel.clone();
                ui.line(Line::new(PlotPoints::from_explicit_callback(move |t| channel.interpolate(t), .., 200)));
            }
        }
    });
}
