import { invoke } from "@tauri-apps/api";
import { useEffect, useRef } from "react";
import { useParentSize } from "./useParentSize";

export function Canvas() {
  const canvasRef = useRef(null);
  const { width, height } = useParentSize(canvasRef);

  useEffect(() => {
    if (canvasRef.current != null) {
      const ctx = canvasRef.current.getContext("2d");

      const draw = (canvasState) => {
        ctx.clearRect(0, 0, width, height);
        ctx.beginPath();

        if (canvasState.channel1.length > 0) {
          const [first, ...rest] = canvasState.channel1;
          ctx.moveTo(first.x, first.y);
          ctx.lineTo(first.x, first.y);
          rest.forEach(([x, y]) => {
            ctx.lineTo(x, y);
          });
          ctx.stroke();
        }
      };

      let frameId = null;
      const render = () => {
        invoke("get_canvas_state", { width, height })
          .then((canvasState) => {
            draw(canvasState);
          })
          .catch(console.error);
        frameId = window.requestAnimationFrame(render);
      };

      render();

      return () => {
        if (frameId) {
          window.cancelAnimationFrame(frameId);
        }
      };
    }
  }, [canvasRef, width, height]);

  return <canvas width={width} height={height} ref={canvasRef} />;
}
