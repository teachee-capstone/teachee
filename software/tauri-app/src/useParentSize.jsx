import { useEffect, useState } from "react";

export function useParentSize(ref) {
  const [size, setSize] = useState({ width: 0, height: 0 });

  useEffect(() => {
    if (ref.current != null) {
      const { parentNode } = ref.current;

      const handleResize = () => {
        const rect = parentNode.getBoundingClientRect();
        setSize({
          width: Math.floor(rect.width),
          height: Math.floor(rect.height),
        });
      };

      handleResize();
      window.addEventListener("resize", handleResize);

      return () => {
        window.removeEventListener("resize", handleResize);
      };
    }
  }, [ref]);

  return size;
}
