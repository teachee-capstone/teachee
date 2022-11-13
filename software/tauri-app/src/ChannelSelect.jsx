import { FormControl, InputLabel, MenuItem, Select } from "@mui/material";

export function ChannelSelect({ label, value, onChange }) {
  return (
    <FormControl sx={{ width: (t) => t.spacing(24) }}>
      <InputLabel>{label}</InputLabel>
      <Select label={label} value={value} onChange={onChange}>
        <MenuItem value="off">Off</MenuItem>
        <MenuItem value="triangleWave">Triangle Wave</MenuItem>
      </Select>
    </FormControl>
  );
}
