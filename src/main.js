import Web3 from 'web3'
import { newKitFromWeb3 } from '@celo/contractkit'
import BigNumber from "bignumber.js"
import marketplaceAbi from '../contract/marketplace.abi.json'
import erc20Abi from "../contract/erc20.abi.json"

const ERC20_DECIMALS = 18  //for wei or gwei
const MPContractAddress = "0xaCbD8c7177a211480A5E25A9904e4a68e787E4d3"   // contract address for the Ticket Verse
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1" // contract address for the cUSD Token 

let kit
let contract
let tickets = [] // empty array which info of events will be added


/*************************** Prompt Celo Wallet To Allow User Connect **********************************************************/
const connectCeloWallet = async function () {
  if (window.celo) {
      notification("⚠️ Please approve this DApp to use it.")
    try {
      await window.celo.enable()
      notificationOff()

      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
    kit.defaultAccount = accounts[0]

    contract = new kit.web3.eth.Contract(marketplaceAbi, MPContractAddress)

    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}


/*************************** Retrieving Balance Of User From Their Celo Wallet    **********************************************************/
  const getBalance = async function () {
    const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
    const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
    document.querySelector("#balance").textContent = cUSDBalance
    document.querySelector("#status").textContent = 'Disconnect'
  }

  /*************************** Renders The Ticket Array After Info Has Been Pushed Into It **********************************************************/
  const getTickets = async function() {
    const _ticketLength = await contract.methods.getTicketsLength().call()
    const _tickets = []
    for (let i = 0; i < _ticketLength; i++) {
        let _ticket = new Promise(async (resolve, reject) => {
          let p = await contract.methods.viewEventTicket(i).call()
          resolve({
            index: i,
            owner: p[0],
            name: p[1],
            image: p[2],
            description: p[3],
            location: p[4],
            quantity: new BigNumber(p[5]),
            sold: p[6],
            price: new BigNumber(p[7]),
            soldOut: p[8]
          })
          
        })
        _tickets.push(_ticket)
      }
     
      tickets = await Promise.all(_tickets)
      renderTickets()
    }

    function renderTickets() {
      document.getElementById("marketplace").innerHTML = ""
      tickets.forEach((_ticket) => {
        const newDiv = document.createElement("div")
        newDiv.className = "col-md-4"
        newDiv.innerHTML = productTemplate(_ticket)
        document.getElementById("marketplace").appendChild(newDiv)
      })
    }


    /*************************** Template Where The Added Tickets Will Be Displayed **********************************************************/
    
    function productTemplate(_ticket) {
      
      return `
        <div class="card mb-4">
          <img class="card-img-top" src="${_ticket.image}" alt="...">
          <div class="position-absolute top-0 end-0 ">
            <div class = "bg-warning mt-4 px-2 py-1 rounded-start">
            ${_ticket.quantity} tickets
            </div>
  
            <div class = "bg-warning mt-4 px-2 py-1 rounded-start">
            ${_ticket.sold} Sold
            </div>
          </div>
          
  
          <div class="card-body text-left p-4 position-relative">
          <div class="translate-middle-y position-absolute top-0">
          ${identiconTemplate(_ticket.owner)}
          </div>
          <h2 class="card-title fs-4 fw-bold mt-2">${_ticket.name}</h2>
          <p class="card-text mb-4" style="min-height: 82px">
            ${_ticket.description}             
          </p>
          <p class="card-text mt-4">
            <i class="bi bi-geo-alt-fill"></i>
            <span>${_ticket.location}</span>
          </p>

          ${(_ticket.owner === kit.defaultAccount) ? `<div class="d-grid gap-2">
          <button type = "button" class= "btn btn-secondary buyBtn btn-lg" id=${_ticket.index} disabled>
          Buy for ${_ticket.price.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
          </button>
        </div>`
        :
        _ticket.soldOut === true ? `<div class="d-grid gap-2">
      <button type = "button" class="btn btn-lg btn-outline-dark resellBtn fs-6 p-3"  id=${_ticket.index} disabled>
        Sold Out
      </button>
    </div>`
         :
            `<div class="d-grid gap-2">
                <button type = "button" class="btn btn-lg btn-outline-success buyBtn fs-6 p-3" id=${
                  _ticket.index
                }>
                  Buy for ${_ticket.price.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
                </button>
              </div>`
          }
        </div>
      </div>
    `
  }

  window.addEventListener("load", async () => {
    notification("⌛ Loading...")
    await connectCeloWallet()
  await getBalance()
  await getTickets()
  notificationOff()
  })



/*************************** Appends The Form Input Value To The Template **********************************************************/
    document.querySelector("#newTicketBtn")
  .addEventListener("click", async (e) => {
    const params = [
      document.getElementById("newTicketName").value,
      document.getElementById("newImgUrl").value,
      document.getElementById("newEventDescription").value,
      document.getElementById("newLocation").value,
      new BigNumber(document.getElementById("newQuantity").value)
      .toFixed()
      .toString(),
      new BigNumber(document.getElementById("newPrice").value)
      .shiftedBy(ERC20_DECIMALS)
      .toString()
    ]
    notification(`⌛ Adding "${params[0]}"...`)
    try {
        const result = await contract.methods
          .ListEventTicket(...params)
          .send({ from: kit.defaultAccount })
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }
      notification(`🎉 You successfully added "${params[0]}".`)
      getTickets()
    })

  window.addEventListener('load', async () => {
    notification("⌛ Loading...")
    await connectCeloWallet()
    await getBalance()
    notificationOff()
  });

 

  
/*************************** Displays An Icon That Links To The User Address **********************************************************/
function identiconTemplate(_address) {
    const icon = blockies
      .create({
        seed: _address,
        size: 8,
        scale: 16,
      })
      .toDataURL()
  
    return `
    <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
      <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
          target="_blank">
          <img src="${icon}" width="48" alt="${_address}">
      </a>
    </div>
    `
  }


/*************************** Append The Notification Element**********************************************************/
  function notification(_text) {
    document.querySelector(".alert").style.display = "block"
    document.querySelector("#notification").textContent = _text
  }
  
  function notificationOff() {
    document.querySelector(".alert").style.display = "none"
  }

  
  /*************************** Getting Wallet Approval To Spend **********************************************************/
  async function approve(_price) {
    const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)
  
    const result = await cUSDContract.methods
      .approve(MPContractAddress, _price)
      .send({ from: kit.defaultAccount })
    return result
  }

  /*************************** Contains The Buy And Resell Functions**********************************************************/
  document.querySelector("#marketplace").addEventListener("click", async (e) => {
    if (e.target.className.includes("buyBtn")) {
      const index = e.target.id
      notification("⌛ Waiting for payment approval...")
      try {
        await approve(tickets[index].price)
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }
      notification(`⌛ Awaiting payment for "${tickets[index].name}"...`)
      try {
        const result = await contract.methods
          .buyTicket(index)
          .send({ from: kit.defaultAccount })
        notification(`🎉 You successfully bought "${tickets[index].name}".`)
        getTickets()
        getBalance()
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }
    }

    if (e.target.className.includes("resellBtn")) {
      const index = e.target.id
      let price = prompt (`Enter new price for "${tickets[index].name} (cUSD) ":`)
      if (price != null) {
        price= new BigNumber(price).shiftedBy(ERC20_DECIMALS).toString()
        notification(`⌛ Reselling "${tickets[index].name}"...`)
        try {
          const result = await contract.methods
            .reSellTicket(index,price)
            .send({ from: kit.defaultAccount })
        } catch (error) {
          notification(`⚠️ ${error}.`)
        }
        notification(`🎉 You successfully resold "${tickets[index].name}". 🎉`)
        getTickets()
        getBalance() 
      }
      else {
        alert("⚠️ You must enter a price.")
      }
    }
  })

 