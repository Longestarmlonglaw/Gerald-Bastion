import { multiline } from 'common/string';
import { type Antagonist, Category } from '../base';

export const ARCFIEND_MECHANICAL_DESCRIPTION = multiline`
      Drain the station's electrical grid to fuel your powers and upgrades,
      and travel unseen through its cables. You are immune to electric shocks,
      but EMPs will hurt you and you have no protection against brute damage.
      Complete your objectives, then escape alive.
   `;

const Arcfiend: Antagonist = {
  key: 'arcfiend',
  name: 'Arcfiend',
  description: [
    multiline`
      Something in the wiring woke up hungry. You can feel every cable and
      APC on the station humming, and all that power is yours for the taking.
    `,
    ARCFIEND_MECHANICAL_DESCRIPTION,
  ],
  category: Category.Roundstart,
};

export default Arcfiend;
