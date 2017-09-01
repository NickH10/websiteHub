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
	$('body').mousemove(function( event ) {

		var containerWidth = $(this).innerWidth(),
		    containerHeight = $(this).innerHeight(),
		    mousePosX = ((event.pageX / containerWidth) * 100)*.1,
		    mousePosY = ((event.pageY / containerHeight) * 100)*.1;

		//want to add 50 to start at 50% default and then adjust according to mouse position
		$(this).css('background-position', (50 + mousePosX) + '%' + ' ' + (50 + mousePosY) + '%');
	});
}