import { multiline } from 'common/string';
import { type Antagonist, Category } from '../base';
import { ARCFIEND_MECHANICAL_DESCRIPTION } from './arcfiend';

const ArcfiendMidround: Antagonist = {
  key: 'arcfiendmidround',
  name: 'Arcfiend (Midround)',
  description: [
    multiline`
      A form of arcfiend that awakens at any point in the middle of the shift.
    `,
    ARCFIEND_MECHANICAL_DESCRIPTION,
  ],
  category: Category.Midround,
};

export default ArcfiendMidround;
