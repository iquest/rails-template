import Flatpickr from "stimulus-flatpickr";
import { Czech } from "flatpickr/dist/l10n/cs.js";

import "flatpickr/dist/themes/light.css";

// creates a new Stimulus controller by extending stimulus-flatpickr wrapper controller
export default class extends Flatpickr {
    initialize() {
        // set language (you can also set some global setting for all time pickers)
        this.config = {
            locale: Czech
        };
    }
}
