import React from 'react';
import { make as PMMRoot } from './PMMRoot.bs.js';
import withSentry from '../routes/withSentry.js';

// `hyperPMM` entry point: mounts the PMM navigator straight away; component
// name and prop shape (`props`, `rootTag`) match the `hyperSwitch` root.
const NewPMMApp = props => {
  return (
    <PMMRoot
      props={props.props}
      rootTag={props.rootTag}
    />
  );
};

export default (
  withSentry(NewPMMApp)
);
