$(document).ready(function(){

	backgroundParallax();

});

// change background size on window resize
// $(window).resize(function() {
// 	$('html').css({
// 		width: $(window).outerWidth(),
// 		height: $(window).outerHeight()
// 	})
// })

// toggles whether hamburger is on or off
function hamburgerToggle(element) {
    element.classList.toggle('toggled');
    $("#overlay").toggleClass('toggled');
}

// creates background parallax effect
var backgroundParallax = function() {
	$('#container').mousemove(function( event ) {
		var containerWidth = $(this).innerWidth(),
		    containerHeight = $(this).innerHeight(),
		    mousePositionX = ((event.pageX / containerWidth) * 100)*.05,
		    mousePositionY = ((event.pageY /containerHeight) * 100)*.05;

		$(this).css('background-position', mousePositionX + '%' + ' ' + mousePositionY + '%');
	});
}