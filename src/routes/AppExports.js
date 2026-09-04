export {make as default} from './App.bs.js';
export {
  make as HeadlessApp,
  run as runHeadlessTask,
} from '../headless/HeadlessTask.bs.js';

// import {ActivityIndicator, View} from 'react-native';

// export default App = props => {
//   return (
//     <View
//       style={{
//         backgroundColor:
//           props.props.type == 'card' ? 'transparent' : '#00000070',
//         flex: 1,
//         justifyContent: 'center',
//       }}>
//       <ActivityIndicator size="large" />
//     </View>
//   );
// };
