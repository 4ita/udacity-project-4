import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';

(async () => {
  let result = null;

  let contract = new Contract('localhost', () => {
    // Read transaction
    contract.isOperational((error, result) => {
      console.log(error, result);
      display('Operational Status', 'Check if contract is operational', [
        { label: 'Operational Status', error: error, value: result },
      ]);
    });

    // User-submitted transaction
    DOM.elid('submit-oracle').addEventListener('click', () => {
      let flight = DOM.elid('flight-number').value;
      // Write transaction
      contract.fetchFlightStatus(flight, (error, result) => {
        display('Oracles', 'Trigger oracles', [
          {
            label: 'Fetch Flight Status',
            error: error,
            value: result.flight + ' ' + result.timestamp,
          },
        ]);
      });
    });

    // User-submitted transaction
    DOM.elid('submit-fund').addEventListener('click', () => {
      // Convert to wei
      let amount = DOM.elid('fund-amount').value * 10 ** 18;
      // Write transaction
      contract.fund(amount + '', (error, result) => {
        console.log(error, result);
      });
    });

    // User-submitted transaction
    DOM.elid('submit-buy').addEventListener('click', () => {
      let flightId = document.querySelector(
        'input[name="flightInsurance"]:checked'
      ).value;
      // Convert to wei
      let amount = DOM.elid('insurance-amount').value * 10 ** 18;
      // Write transaction
      contract.buyInsurance(flightId, amount + '', (error, result) => {
        console.log(error, result)
      });
    });

    // User-submitted transaction
    DOM.elid('submit-credit').addEventListener('click', () => {
      let flightId = document.querySelector(
        'input[name="delayedFlight"]:checked'
      ).value;
      // Write transaction
      contract.credit(flight, (error, result) => {
        console.log(error, result)
      });
    });

    // User-submitted transaction
    DOM.elid('submit-withdraw').addEventListener('click', () => {
      let flightId = document.querySelector(
        'input[name="delayedFlight"]:checked'
      ).value;
      // Write transaction
      contract.withdraw(flight, (error, result) => {
        console.log(error, result)
      });
    });
  });
})();

function display(title, description, results) {
  let displayDiv = DOM.elid('display-wrapper');
  let section = DOM.section();
  section.appendChild(DOM.h2(title));
  section.appendChild(DOM.h5(description));
  results.map((result) => {
    let row = section.appendChild(DOM.div({ className: 'row' }));
    row.appendChild(DOM.div({ className: 'col-sm-4 field' }, result.label));
    row.appendChild(
      DOM.div(
        { className: 'col-sm-8 field-value' },
        result.error ? String(result.error) : String(result.value)
      )
    );
    section.appendChild(row);
  });
  displayDiv.append(section);
}
