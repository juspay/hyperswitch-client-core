import React from 'react';
import App from './AppExports.js';
import withSentry from './withSentry.js';
export { HeadlessApp } from './AppExports.js';

const NewApp = props => {
  return (
    <App
      props={props.props}
      rootTag={props.rootTag}
    />
  );
};

export default (
  withSentry(NewApp)
);
