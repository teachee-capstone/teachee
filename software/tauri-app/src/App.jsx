import {
  AppBar,
  Card,
  Container,
  Stack,
  Toolbar,
  Typography,
} from "@mui/material";
import { Canvas } from "./Canvas";
import { ChannelSelect } from "./ChannelSelect";
import { useScopeState } from "./useScopeState";

export default function App() {
  const [scopeState, updateScopeState] = useScopeState();

  return (
    scopeState && (
      <>
        <AppBar position="absolute">
          <Toolbar>
            <Stack
              direction="row"
              justifyContent="space-between"
              sx={{ flex: "1 1 auto" }}
            >
              <Typography component="h1" variant="h6" color="inherit" noWrap>
                TeachEE
              </Typography>
              <Typography variant="h6" color="inherit" noWrap>
                Flag: {scopeState.flag ? "On" : "Off"}
              </Typography>
            </Stack>
          </Toolbar>
        </AppBar>
        <Container
          component="main"
          maxWidth="lg"
          sx={{
            py: 2,
            height: "100vh",
            display: "flex",
            flexDirection: "column",
          }}
        >
          {/* Empty toolbar ensures components aren't hidden behind position="absolute" Toolbar above. */}
          <Toolbar />
          <Card variant="outlined" sx={{ flex: "1 1 auto" }}>
            <Canvas />
          </Card>
          <Card variant="outlined" sx={{ mt: 2, p: 2 }}>
            <Stack direction="row" spacing={2}>
              <ChannelSelect
                label="Channel 1"
                value={scopeState.channel1}
                onChange={(e) => {
                  updateScopeState({
                    setChannel1: e.target.value,
                  });
                }}
              />
            </Stack>
          </Card>
        </Container>
      </>
    )
  );
}
