import { invoke } from "@tauri-apps/api";
import { listen } from "@tauri-apps/api/event";
import { useEffect, useState } from "react";

export function useScopeState() {
  const [state, setState] = useState(null);

  useEffect(() => {
    invoke("get_scope_state")
      .then((state) => {
        setState(state);
      })
      .catch(console.error);

    const unlisten = listen("scope_state", (event) => {
      setState(event.payload);
    });

    return () => {
      unlisten.then((f) => {
        f();
      });
    };
  }, []);

  const update = (event) => {
    invoke("update_scope_state", { event });
  };

  return [state, update];
}
