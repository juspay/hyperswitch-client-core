import {groupFields, classify} from '../src/components/dynamic/FieldGrouper.bs.js';

const field = (fieldRenderType, path, order = 0) => ({
  fieldRenderType,
  confirmRequestWritePath: path,
  fieldDisplayOrder: order,
  fieldLabel: path,
  fieldPlaceholder: '',
  isRequired: true,
  fieldOptions: [],
  fieldValue: undefined,
});

const tagOf = value => (typeof value === 'string' ? value : value.TAG);

const CARD_FIELDS = [
  field('CardNumber', 'payment_method_data.card.card_number', 0),
  field('CardExpiryMonth', 'payment_method_data.card.card_exp_month', 1),
  field('CardExpiryYear', 'payment_method_data.card.card_exp_year', 2),
  field('Cvc', 'payment_method_data.card.card_cvc', 3),
];

describe('CardHolderName is card data', () => {
  it('classifies to the Card group, not the Name group', () => {
    expect(tagOf(classify(field('CardHolderName', 'payment_method_data.card.card_holder_name')))).toBe(
      'Card',
    );
  });

  it('keeps FirstName and LastName in the Name group — they are billing data', () => {
    expect(tagOf(classify(field('FirstName', 'payment_method_data.billing.address.first_name')))).toBe(
      'Name',
    );
    expect(tagOf(classify(field('LastName', 'payment_method_data.billing.address.last_name')))).toBe(
      'Name',
    );
  });
});

describe('grouping produces exactly one owner of the cardholder name', () => {
  it('a card + cardholder-name config yields ONE card group and NO name group', () => {
    const groups = groupFields([
      ...CARD_FIELDS,
      field('CardHolderName', 'payment_method_data.card.card_holder_name', 4),
    ]).map(tagOf);

    expect(groups).toContain('CARD');
    expect(groups).not.toContain('FULLNAME');
    expect(groups.filter(g => g === 'CARD')).toHaveLength(1);
  });

  it('the cardholder field travels WITH the card group, so the library can see it', () => {
    const groups = groupFields([
      ...CARD_FIELDS,
      field('CardHolderName', 'payment_method_data.card.card_holder_name', 4),
    ]);
    const card = groups.find(g => tagOf(g) === 'CARD');
    const renderTypes = card._0.map(f => f.fieldRenderType);
    expect(renderTypes).toContain('CardHolderName');
  });

  it('billing names still produce a name group, and it is the only one', () => {
    const groups = groupFields([
      ...CARD_FIELDS,
      field('FirstName', 'payment_method_data.billing.address.first_name', 4),
      field('LastName', 'payment_method_data.billing.address.last_name', 5),
    ]).map(tagOf);

    expect(groups).toContain('CARD');
    expect(groups.filter(g => g === 'FULLNAME')).toHaveLength(1);
  });

  it('a config with BOTH a card cardholder name and billing names keeps them apart', () => {
    const groups = groupFields([
      ...CARD_FIELDS,
      field('CardHolderName', 'payment_method_data.card.card_holder_name', 4),
      field('FirstName', 'payment_method_data.billing.address.first_name', 5),
      field('LastName', 'payment_method_data.billing.address.last_name', 6),
    ]);

    const card = groups.find(g => tagOf(g) === 'CARD');
    const name = groups.find(g => tagOf(g) === 'FULLNAME');

    expect(card._0.map(f => f.fieldRenderType)).toContain('CardHolderName');
    expect(name._0.map(f => f.fieldRenderType).sort()).toEqual(['FirstName', 'LastName']);
    expect(name._0.map(f => f.fieldRenderType)).not.toContain('CardHolderName');
  });

  it('no group ever carries a card write path outside the card group', () => {
    const groups = groupFields([
      ...CARD_FIELDS,
      field('CardHolderName', 'payment_method_data.card.card_holder_name', 4),
      field('FirstName', 'payment_method_data.billing.address.first_name', 5),
      field('Email', 'payment_method_data.billing.email', 6),
    ]);

    for (const group of groups) {
      if (tagOf(group) === 'CARD') continue;
      for (const f of group._0) {
        expect(f.confirmRequestWritePath).not.toMatch(/^payment_method_data\.card\./);
      }
    }
  });
});
