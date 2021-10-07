import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

// Upon startup, 20+ oracles are registered and their assigned indexes are persisted in memory
const ORACLES_COUNT = 21;

flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log(event)
});

const app = express();
app.get('/api', async (req, res) => {
    // Upon startup, 20+ oracles are registered and their assigned indexes are persisted in memory
    for (let i = 1; i < ORACLES_COUNT; i++) {
      await config.flightSuretyApp.registerOracle({
        from: web3.eth.accounts[i],
        value: fee,
      });
      let result = await config.flightSuretyApp.getMyIndexes.call({
        from: web3.eth.accounts[i],
      });
      console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
    }

    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;
