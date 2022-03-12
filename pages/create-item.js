import { useState } from "react";
import { ethers } from "ethers";
import { create as ipfsHttpClient } from "ipfs-http-client";
import { useRouter } from "next/router";
import Web3Modal from "web3modal";

const client = ipfsHttpClient("https://ipfs.infura.io:5001/api/v0");
import { nftAddress, nftmarketAddress } from "../config";
import NFT from "../artifacts/contracts/NFT.sol/NFT.json";
import MARKET from "../artifacts/contracts/NFTMarket.sol/NFTMarket.json";

export default function CreateItem() {
  const [fileUri, setFileUri] = useState(null);
  const [formInput, updateFormInput] = useState({
    price: "",
    name: "",
    description: "",
  });
  const router = useRouter();

  async function onChange(e) {
    const file = e.target.files[0];
    try {
      const added = await client.add(file, {
        progress: (prog) => console.log(`received:${prog}`),
      });

      const url = `http://ipfs.infura.io/ipfs/${added.path}`;
      setFileUri(url);
    } catch (e) {
      console.log(e);
    }
  }
  async function createItem() {
    const { name, description, price } = formInput;
    console.log(price);
    if (!name || !description || !price || !fileUri) {
        console.log(formInput,fileUri)
        return
    };
    const data = JSON.stringify({
      name,
      description,
      image: fileUri,
    });
    try {
      const added = await client.add(data, {
        progress: (prog) => console.log(`received:${prog}`),
      });

      const url = `http://ipfs.infura.io/ipfs/${added.path}`;
      createSale(url);
    } catch (e) {
      console.log(e);
    }
  }
  async function createSale(url) {
    const web3modal = new Web3Modal();
    const connection = await web3modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);
    const signer = provider.getSigner();

    let contract = new ethers.Contract(nftAddress, NFT.abi, signer);
    let transaction = await contract.createToken(url);
    let tx = await transaction.wait();
    console.log(tx.events);
    let event = tx.events[0];

    let value = event.args[2];
    let tokenId = value.toNumber();

    const price = ethers.utils.parseUnits(formInput.price, "ether");
    contract = new ethers.Contract(nftmarketAddress, MARKET.abi, signer);
    let listingPrice = await contract.getListingPrice();
    listingPrice = listingPrice.toString();

    transaction = await contract.createMarketItem(nftAddress, tokenId, price, {
      value: listingPrice,
    });
    await transaction.wait();
    router.push("/");
  }

  return (
    <div className="flex justify-center">
      <div className="w-1/2 flex flex-col pb-12">
        <input
          placeholder="Asset Name"
          className="mt-8 border rounded p-4"
          onChange={(e) =>
            updateFormInput({ ...formInput, name: e.target.value })
          }
        />
        <textarea
          placeholder="Asset Description"
          className="mt-2 border rounded p-4"
          onChange={(e) =>
            updateFormInput({ ...formInput, description: e.target.value })
          }
        />
        <input
          placeholder="Asset Price in Eth"
          className="mt-2 border rounded p-4"
          onChange={(e) =>
            updateFormInput({ ...formInput, price: e.target.value })
          }
        />
        <input type="file" name="Asset" className="my-4" onChange={onChange} />
        {fileUri && <img className="rounded mt-4" width="350" src={fileUri} />}
        <button
          onClick={createItem}
          className="font-bold mt-4 bg-pink-500 text-white rounded p-4 shadow-lg"
        >
          Create NFT
        </button>
      </div>
    </div>
  );
}
