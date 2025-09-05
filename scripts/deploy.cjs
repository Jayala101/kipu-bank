const hre = require("hardhat");
const { ethers } = require("hardhat");

async function verify(contractAddress, args) {
  console.log("Verificando contrato...");
  try {
    await hre.run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
    console.log("¡Contrato verificado!");
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("El contrato ya está verificado!");
    } else {
      console.error("Error al verificar el contrato:", e);
    }
  }
}

async function waitForConfirmations(tx, confirmations = 5) {
  console.log(`Esperando ${confirmations} confirmaciones...`);
  const receipt = await tx.wait(confirmations);
  console.log(`Transacción confirmada en el bloque ${receipt.blockNumber}`);
  return receipt;
}

async function deploy() {
  try {
    // Obtener el deployer
    const [deployer] = await ethers.getSigners();
    
    // Obtener el balance usando provider.getBalance()
    const balance = await ethers.provider.getBalance(deployer.address);
    const minBalance = ethers.parseEther("0.05"); // Mínimo 0.05 ETH necesario
    
    console.log("Desplegando con la cuenta:", deployer.address);
    console.log("Balance de la cuenta:", ethers.formatEther(balance), "ETH");

    // Verificar balance mínimo
    if (balance < minBalance) {
      throw new Error(`Balance insuficiente. Necesitas al menos 0.05 ETH para desplegar. Obtén ETH de prueba en:
      - https://sepoliafaucet.com/
      - https://sepolia-faucet.pk910.de/`);
    }

    // Configurar los parámetros del contrato
    const BANK_CAP = ethers.parseEther("10");
    const MAX_WITHDRAWAL = ethers.parseEther("1");

    // Desplegar el contrato
    console.log("\nDesplegando KipuBank...");
    console.log("Límite del banco:", ethers.formatEther(BANK_CAP), "ETH");
    console.log("Límite de retiro:", ethers.formatEther(MAX_WITHDRAWAL), "ETH");

    // Obtener el precio del gas actual
    const gasPrice = await ethers.provider.getFeeData();
    console.log("Precio del gas actual:", ethers.formatUnits(gasPrice.gasPrice, "gwei"), "gwei");

    const KipuBank = await ethers.getContractFactory("KipuBank");
    const kipuBank = await KipuBank.deploy(
      BANK_CAP,
      MAX_WITHDRAWAL,
      {
        gasLimit: 3000000, // Límite de gas explícito
        maxFeePerGas: gasPrice.maxFeePerGas, // Máximo precio por gas
        maxPriorityFeePerGas: gasPrice.maxPriorityFeePerGas // Propina para los mineros
      }
    );
    
    // Esperar el despliegue
    await kipuBank.waitForDeployment();
    const address = await kipuBank.getAddress();
    console.log("KipuBank desplegado en:", address);

    // Esperar confirmaciones y verificar
    console.log("\nEsperando confirmaciones...");
    await new Promise(resolve => setTimeout(resolve, 30000)); // 30 segundos
    await verify(address, [BANK_CAP, MAX_WITHDRAWAL]);

    return { address, deployer: deployer.address };
  } catch (error) {
    console.error("Error durante el despliegue:", error);
    throw error;
  }
}

// Ejecutar el despliegue
if (require.main === module) {
  deploy()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { deploy };