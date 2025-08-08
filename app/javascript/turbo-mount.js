import plugin, { TurboMount } from "turbo-mount/react";
import { registerComponents } from "turbo-mount/registerComponents/vite";

const controllers = import.meta.glob("./controllers/**/*_controller.js", { eager: true });
const components = import.meta.glob("./components/**/*.tsx", { eager: true });

// #STYLE_GUIDE: Transform snake_case props to camelCase for React components
// This only transforms top-level keys, leaving nested objects (like Blueprinted data) unchanged
const transformPropsToCallback = (props) => {
  if (typeof props !== 'object' || props === null || Array.isArray(props)) {
    return props;
  }
  
  const transformed = {};
  for (const [key, value] of Object.entries(props)) {
    // Only transform top-level snake_case keys to camelCase
    // Leave nested objects unchanged (they're already camelCased by Blueprinter)
    const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
    transformed[camelKey] = value;
  }
  return transformed;
};

// Create a custom plugin that transforms props before mounting
const transformingPlugin = {
  ...plugin,
  mountComponent: (mountProps) => {
    const { props, ...rest } = mountProps;
    const transformedProps = transformPropsToCallback(props);
    return plugin.mountComponent({ ...rest, props: transformedProps });
  }
};

const turboMount = new TurboMount();
registerComponents({ plugin: transformingPlugin, turboMount, components, controllers });

// Debug: Show registered components
console.log("Registered components:", Object.keys(components));
