import { createCardField } from './createCardField';
import type { CardCVCFieldProps } from './types';

export const CardCVCField = createCardField<CardCVCFieldProps>(
  'cardCvc',
  'CardCVCField'
);
