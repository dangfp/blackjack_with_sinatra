$(document).ready(function(){
  $(document).on('click', 'form#hit_form input', function(){
    alert("player hits");
    $.ajax({
      type: 'POST',
      url: '/game/player/hit'
    }).done(function(msg){
      $('div#game').replaceWith(msg);
    });
    return false;
  });

  $(document).on('click', 'form#stay_form input', function(){
    alert("player stays");
    $.ajax({
      type: 'POST',
      url: '/game/player/stay'
    }).done(function(msg){
      $('div#game').replaceWith(msg);
    });
    return false;
  });
});
