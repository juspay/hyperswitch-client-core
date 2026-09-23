// Must come first: tells the bundler's ScriptManager where chunk files live.
import './src/chunks/ScriptResolver.bs.js';
import { AppRegistry } from 'react-native';
import {
  FIELD_COMPONENT,
  FORM_COMPONENT,
  FieldSurface,
  FormSurface,
  registerHostedAdapters,
  startCommands,
} from './src/payment-methods/hosted';

AppRegistry.registerComponent(FORM_COMPONENT, () => FormSurface);
AppRegistry.registerComponent(FIELD_COMPONENT, () => FieldSurface);

// The Hyperswitch vault with each field in a root of its own. Registered here
// and nowhere else: <CardForm> users keep the adapter they have always had.
registerHostedAdapters();
startCommands();
