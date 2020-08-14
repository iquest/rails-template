import $ from 'jquery';
import 'popper.js'
import 'bootstrap'

document.addEventListener('turbolinks:load', () => {
  $('[data-toggle="tooltip"]').tooltip();
  $('[data-toggle="popover"]').popover();
  $('.toast').toast({ autohide: false });
  $('#toast').toast('show');
});
