let map, directionsService, directionsRenderer;

let isMapInitialized = false;
let isRouteCalculated = false;

// Function to initialize the map
// Attach to window to ensure global access
window.initAutocomplete = function () {
    if (typeof google !== 'undefined' && google.maps && google.maps.places) {
        console.log("Initializing Autocomplete...");
        document.querySelectorAll('.location-input').forEach((input) => {
            initializeAutocompleteForInput(input);
        });
    } else {
        console.error("Google Maps API is not loaded yet.");
    }
}

// Ensure initializeAutocompleteForInput is also globally accessible
window.initializeAutocompleteForInput = function (input) {
    const autocomplete = new google.maps.places.Autocomplete(input, {
        types: ['geocode']
    });
    autocomplete.setFields(['place_id', 'geometry', 'name', 'formatted_address', 'address_components']);

    autocomplete.addListener('place_changed', function () {
        const place = autocomplete.getPlace();
        if (!place.geometry) {
            alert("No details available for input: '" + place.name + "'");
            return;
        }

        if (place.formatted_address) {
            input.value = place.formatted_address;
        } else if (place.address_components) {
            input.value = getFullAddress(place.address_components);
        } else {
            input.value = place.name;
        }

        // Store the place_id for later use
        input.setAttribute('data-place-id', place.place_id);
        input.setAttribute('data-selected', 'true');
    });

    input.addEventListener('blur', function () {
        if (input.getAttribute('data-selected') === 'true') {
            input.setAttribute('data-selected', 'false');
        }
    });
}

// Function to initialize the map
window.initMap = function () {
    console.log("Google Maps API Loaded. Initializing Map...");

    // Check if already initialized to prevent double initialization
    if (isMapInitialized) {
        console.warn("Map is already initialized. Skipping re-initialization.");
        return;
    }

    // Initialize Map
    map = new google.maps.Map(document.getElementById('map'), {
        center: { lat: -34.397, lng: 150.644 },
        zoom: 8
    });
    directionsService = new google.maps.DirectionsService();
    directionsRenderer = new google.maps.DirectionsRenderer();
    directionsRenderer.setMap(map);
    directionsRenderer.setPanel(document.getElementById('directions-panel'));
    console.log(map, directionsService, directionsRenderer);
    // Initialize Directions Service and Renderer using Promises



    // Initialize Autocomplete for all existing input fields
    initAutocomplete();

    // Attach Event Listener for Add Button using Event Delegation
    document.removeEventListener('click', addDestinationHandler);
    document.addEventListener('click', addDestinationHandler);

    // Attach Submit Event Listener
    const form = document.querySelector('#destination-form');
    if (form) {
        form.removeEventListener('submit', submitFormHandler);
        form.addEventListener('submit', submitFormHandler);
    }

    // Mark Map as Fully Initialized
    isMapInitialized = true;

}

// Promises to ensure initialization order
const initializeDirections = function () {
    return new Promise((resolve, reject) => {
        try {
            // Initialize Directions Service and Renderer
            

            // Check if both are initialized
            if (directionsService && directionsRenderer) {
                resolve();
            } else {
                reject("DirectionsService or DirectionsRenderer is not initialized.");
            }
        } catch (error) {
            reject(error);
        }
    });
}

// Centralized Initialization Check


// Named Event Listener to prevent double listeners
const addDestinationHandler = function (event) {
    if (event.target && event.target.classList.contains('add-destination')) {
        event.preventDefault();
        console.log("Add Button Clicked. Adding new input field...");

        // Create New Input Field
        const newInput = document.createElement('input');
        newInput.type = 'text';
        newInput.className = 'form-control location-input mt-2';
        newInput.placeholder = 'Enter another destination';
        newInput.setAttribute('data-place-id', ''); // Store place_id here
        document.querySelector('#destination-form .col-md-6').appendChild(newInput);

        // Initialize Autocomplete for the new input
        initializeAutocompleteForInput(newInput);
    }
}

// Named Event Listener to prevent double listeners
const submitFormHandler = function (event) {
    event.preventDefault();
    let waypoints = [];

    const inputs = document.querySelectorAll('.location-input');
    inputs.forEach((input) => {
        const placeId = input.getAttribute('data-place-id');
        const location = input.value.trim();
        
        // Only add to waypoints if placeId and location are not empty
        if (placeId && location !== "") {
            waypoints.push({
                location: { placeId: placeId },
                stopover: true
            });
        }
        console.log(waypoints);
    });

    // Ensure at least two valid locations are provided
    if (waypoints.length < 2) {
        alert('Please enter at least two valid destinations.');
        console.warn('Insufficient waypoints:', waypoints);
        return;
    }

    // Trigger Route Calculation only if Initialization is Confirmed

        // Clear old directions before calculating new route
        directionsRenderer.setDirections({ routes: [] });
        calculateAndDisplayRoute(waypoints);
    
}


calculateAndDisplayRoute = function(waypoints) {
    initMap();
    console.log(map, directionsService, directionsRenderer);
  console.log("Calculating Route with Waypoints:", waypoints);

  directionsService.route(
    {
      origin: waypoints[0].location,
      destination: waypoints[waypoints.length - 1].location,
      waypoints: waypoints.slice(1, waypoints.length - 1),
      optimizeWaypoints: true,
      travelMode: google.maps.TravelMode.DRIVING
    },
    function(response, status) {
      console.log('Directions API Response:', response);
      console.log('Directions API Status:', status);

      if (status === google.maps.DirectionsStatus.OK) {
        directionsRenderer.setDirections(response);
        isRouteCalculated = false;
      } else {
        alert('Failed to get route: ' + status);
        console.error('Failed to get route: ' + status);
        isRouteCalculated = false;
      }
    }
  );
}
